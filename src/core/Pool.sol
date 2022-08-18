// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { PoolConfig } from "./PoolConfig.sol";
import { PoolMath } from "./PoolMath.sol";
import { PoolOracle } from "./PoolOracle.sol";
import { MintableTokenInterface } from "../interfaces/MintableTokenInterface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Constants } from "./Constants.sol";

contract Pool is Constants, ReentrancyGuard {
  using SafeERC20 for IERC20;

  error Pool_BadAmountOut();
  error Pool_BadArgument();
  error Pool_BadPositionSize();
  error Pool_CollateralTooSmall();
  error Pool_CoolDown();
  error Pool_FailCheckPosition();
  error Pool_Forbidden();
  error Pool_LeverageDisabled();
  error Pool_LiquidityBuffer();
  error Pool_LiquidityMismatch();
  error Pool_InsufficientLiquidity();
  error Pool_InsufficientLiquidityMint();
  error Pool_OverUsdDebtCeiling();
  error Pool_OverShortCeiling();
  error Pool_Slippage();
  error Pool_SwapDisabled();

  MintableTokenInterface public plp;

  PoolConfig public config;
  PoolMath public poolMath;
  PoolOracle public oracle;

  mapping(address => uint256) public totalOf;
  mapping(address => uint256) public liquidityOf;
  mapping(address => uint256) public reservedOf;

  mapping(address => uint256) public sumFundingRateOf;
  mapping(address => uint256) public lastFundingTimeOf;

  // Short
  mapping(address => uint256) public shortSizeOf;
  mapping(address => uint256) public shortAveragePriceOf;

  // Fee
  mapping(address => uint256) public feeReserveOf;

  // Debt
  uint256 public totalUsdDebt;
  mapping(address => uint256) public usdDebtOf;
  mapping(address => uint256) public guaranteedUsdOf;

  // AUM
  uint256 public additionalAum;
  uint256 public discountedAum;

  // LP
  mapping(address => uint256) public lastAddLiquidityAtOf;

  // Position
  struct Position {
    uint256 size;
    uint256 collateral; // collateral value in USD
    uint256 averagePrice;
    uint256 entryFundingRate;
    uint256 reserveAmount;
    int256 realizedPnl;
    uint256 lastIncreasedTime;
  }
  mapping(bytes32 => Position) public positions;
  mapping(address => mapping(address => bool)) public approvedPlugins;

  event UpdateFundingRate(address token, uint256 sumFundingRate);
  event AddLiquidity(
    address account,
    address token,
    uint256 amount,
    uint256 aum,
    uint256 supply,
    uint256 usdDebt,
    uint256 mintAmount
  );
  event CollectSwapFee(address token, uint256 feeUsd, uint256 fee);
  event CollectMarginFee(address token, uint256 feeUsd, uint256 feeTokens);
  event DecreaseGuaranteedUsd(address token, uint256 amount);
  event DecreasePoolLiquidity(address token, uint256 amount);
  event DecreaseUsdDebt(address token, uint256 amount);
  event DecreaseReserved(address token, uint256 amount);
  event DecreaseShortSize(address token, uint256 amount);
  event ExitPool(
    address account,
    address token,
    uint256 usdAmount,
    uint256 amountOut,
    uint256 burnFeeBps
  );
  event JoinPool(
    address account,
    address token,
    uint256 amount,
    uint256 usdDebt,
    uint256 mintFeeBps
  );
  event IncreaseGuaranteedUsd(address token, uint256 amount);
  event IncreasePoolLiquidity(address token, uint256 amount);
  event IncreasePosition(
    bytes32 positionId,
    address subAccount,
    address collateralToken,
    address indexToken,
    uint256 collateralDeltaUsd,
    uint256 sizeDelta,
    Exposure exposure,
    uint256 price,
    uint256 feeUsd
  );
  event IncreaseUsdDebt(address token, uint256 amount);
  event IncreaseReserved(address token, uint256 amount);
  event IncreaseShortSize(address token, uint256 amount);
  event RemoveLiquidity(
    address account,
    address tokenOut,
    uint256 liquidity,
    uint256 aum,
    uint256 supply,
    uint256 usdDebt,
    uint256 amountOut
  );
  event Swap(
    address account,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 amountOutAfterFee,
    uint256 swapFeeBps
  );
  event UpdatePosition(
    bytes32 positionId,
    uint256 size,
    uint256 collateral,
    uint256 averagePrice,
    uint256 entryFundingRate,
    uint256 reserveAmount,
    int256 realizedPnl,
    uint256 price
  );

  constructor(
    MintableTokenInterface _plp,
    PoolConfig _config,
    PoolMath _poolMath,
    PoolOracle _oracle
  ) {
    config = _config;
    poolMath = _poolMath;
    oracle = _oracle;
    plp = _plp;
  }

  modifier allowed(address account) {
    if (account != msg.sender && config.router() != msg.sender) {
      if (!approvedPlugins[account][msg.sender]) revert Pool_Forbidden();
    }
    _;
  }

  // ---------------------------
  // Pool's core functionalities
  // ---------------------------
  function updateFundingRate(address collateralToken, address indexToken)
    public
  {
    if (!config.shouldUpdateFundingRate(collateralToken, indexToken)) return;

    uint256 fundingInterval = config.fundingInterval();

    if (lastFundingTimeOf[collateralToken] == 0) {
      lastFundingTimeOf[collateralToken] =
        (block.timestamp / fundingInterval) *
        fundingInterval;
      return;
    }

    // If block.timestamp is not passed the next funding interval, do nothing.
    if (
      lastFundingTimeOf[collateralToken] + fundingInterval > block.timestamp
    ) {
      return;
    }

    uint256 fundingRate = getNextFundingRate(collateralToken);
    unchecked {
      sumFundingRateOf[collateralToken] =
        sumFundingRateOf[collateralToken] +
        fundingRate;
      lastFundingTimeOf[collateralToken] =
        (block.timestamp / fundingInterval) *
        fundingInterval;
    }

    emit UpdateFundingRate(collateralToken, sumFundingRateOf[collateralToken]);
  }

  function addLiquidity(
    address account,
    address token,
    address receiver
  ) external nonReentrant allowed(account) returns (uint256) {
    // Pull tokens
    uint256 amount = _pullTokens(token);

    // Check
    if (!config.isAcceptToken(token)) revert Pool_BadArgument();
    if (amount == 0) revert Pool_BadArgument();

    uint256 aum = poolMath.getAum18(Pool(address(this)), MinMax.MAX);
    uint256 lpSupply = plp.totalSupply();

    uint256 usdDebt = _join(token, amount, receiver);
    uint256 mintAmount = aum == 0 ? usdDebt : (usdDebt * lpSupply) / aum;

    plp.mint(receiver, mintAmount);

    lastAddLiquidityAtOf[account] = block.timestamp;

    emit AddLiquidity(
      account,
      token,
      amount,
      aum,
      lpSupply,
      usdDebt,
      mintAmount
    );

    return mintAmount;
  }

  function _join(
    address token,
    uint256 amount,
    address receiver
  ) internal returns (uint256) {
    updateFundingRate(token, token);

    uint256 price = oracle.getMinPrice(token);

    uint256 tokenValueUsd = (amount * price) / PRICE_PRECISION;
    uint8 tokenDecimals = config.tokenDecimals(token);
    tokenValueUsd = _convertTokenDecimals(
      tokenDecimals,
      USD_DECIMALS,
      tokenValueUsd
    );
    if (tokenValueUsd == 0) revert Pool_InsufficientLiquidityMint();

    uint256 feeBps = poolMath.getAddLiquidityFeeBps(
      Pool(address(this)),
      token,
      tokenValueUsd
    );
    uint256 amountAfterDepositFee = _collectSwapFee(
      token,
      price,
      amount,
      feeBps
    );
    uint256 usdDebt = _convertTokenDecimals(
      tokenDecimals,
      USD_DECIMALS,
      (amountAfterDepositFee * price) / PRICE_PRECISION
    );

    _increaseUsdDebt(token, usdDebt);
    _increasePoolLiquidity(token, amountAfterDepositFee);

    totalUsdDebt += usdDebt;

    emit JoinPool(receiver, token, amount, usdDebt, feeBps);

    return usdDebt;
  }

  function removeLiquidity(
    address account,
    address tokenOut,
    address receiver
  ) external nonReentrant allowed(account) returns (uint256) {
    uint256 liquidity = plp.balanceOf(address(this));

    if (!config.isAcceptToken(tokenOut)) revert Pool_BadArgument();
    if (liquidity == 0) revert Pool_BadArgument();
    if (
      lastAddLiquidityAtOf[account] + config.liquidityCoolDownDuration() >
      block.timestamp
    ) {
      revert Pool_CoolDown();
    }

    uint256 aum = poolMath.getAum18(Pool(address(this)), MinMax.MIN);
    uint256 lpSupply = plp.totalSupply();

    uint256 lpUsdValue = (liquidity * aum) / lpSupply;
    // Adjust totalUsdDebt if lpUsdValue > totalUsdDebt.
    if (totalUsdDebt < lpUsdValue) totalUsdDebt += lpUsdValue - totalUsdDebt;
    uint256 amountOut = _exit(tokenOut, lpUsdValue, receiver);

    plp.burn(address(this), liquidity);
    _pushTokens(tokenOut, receiver, amountOut);

    emit RemoveLiquidity(
      account,
      tokenOut,
      liquidity,
      aum,
      lpSupply,
      lpUsdValue,
      amountOut
    );

    return amountOut;
  }

  function _exit(
    address token,
    uint256 usdValue,
    address receiver
  ) internal returns (uint256) {
    updateFundingRate(token, token);

    uint256 tokenPrice = oracle.getMaxPrice(token);
    uint256 amountOut = _convertTokenDecimals(
      18,
      config.tokenDecimals(token),
      (usdValue * PRICE_PRECISION) / tokenPrice
    );
    if (amountOut == 0) revert Pool_BadAmountOut();

    _decreaseUsdDebt(token, usdValue);
    _decreasePoolLiquidity(token, amountOut);

    totalUsdDebt -= usdValue;

    uint256 burnFeeBps = poolMath.getRemoveLiquidityFeeBps(
      Pool(address(this)),
      token,
      usdValue
    );
    amountOut = _collectSwapFee(
      token,
      oracle.getMinPrice(token),
      amountOut,
      burnFeeBps
    );
    if (amountOut == 0) revert Pool_BadAmountOut();

    emit ExitPool(receiver, token, usdValue, amountOut, burnFeeBps);

    return amountOut;
  }

  function swap(
    address tokenIn,
    address tokenOut,
    uint256 minAmountOut,
    address receiver
  ) external nonReentrant returns (uint256) {
    // Pull Tokens
    uint256 amountIn = _pullTokens(tokenIn);

    if (!config.isSwapEnable()) revert Pool_SwapDisabled();
    if (!config.isAcceptToken(tokenIn)) revert Pool_BadArgument();
    if (!config.isAcceptToken(tokenOut)) revert Pool_BadArgument();
    if (tokenIn == tokenOut) revert Pool_BadArgument();
    if (amountIn == 0) revert Pool_BadArgument();

    updateFundingRate(tokenIn, tokenIn);
    updateFundingRate(tokenOut, tokenOut);

    uint256 priceIn = oracle.getMinPrice(tokenIn);
    uint256 priceOut = oracle.getMaxPrice(tokenOut);

    uint256 amountOut = (amountIn * priceIn) / priceOut;
    amountOut = _convertTokenDecimals(
      config.tokenDecimals(tokenIn),
      config.tokenDecimals(tokenOut),
      amountOut
    );

    // Adjust USD debt as swap shifted the debt between two assets
    uint256 usdDebt = (amountIn * priceIn) / PRICE_PRECISION;
    usdDebt = _convertTokenDecimals(
      config.tokenDecimals(tokenIn),
      USD_DECIMALS,
      usdDebt
    );

    uint256 swapFeeBps = poolMath.getSwapFeeBps(
      Pool(address(this)),
      tokenIn,
      tokenOut,
      usdDebt
    );
    uint256 amountOutAfterFee = _collectSwapFee(
      tokenOut,
      oracle.getMinPrice(tokenOut),
      amountOut,
      swapFeeBps
    );

    _increasePoolLiquidity(tokenIn, amountIn);
    _increaseUsdDebt(tokenIn, usdDebt);

    _decreasePoolLiquidity(tokenOut, amountOut);
    _decreaseUsdDebt(tokenOut, usdDebt);

    // Buffer check
    if (liquidityOf[tokenOut] < config.tokenBufferLiquidity(tokenOut))
      revert Pool_LiquidityBuffer();

    // Slippage check
    if (amountOutAfterFee < minAmountOut) revert Pool_Slippage();

    // Transfer amount out.
    _pushTokens(tokenOut, receiver, amountOutAfterFee);

    emit Swap(
      receiver,
      tokenIn,
      tokenOut,
      amountIn,
      amountOut,
      amountOutAfterFee,
      swapFeeBps
    );

    return amountOutAfterFee;
  }

  struct IncreasePositionLocalVars {
    address subAccount;
    bytes32 posId;
    uint256 price;
    uint256 feeUsd;
    uint256 collateralDelta;
    uint256 collateralDeltaUsd;
    uint256 reserveDelta;
  }

  /// @notice Increase leverage position size.
  /// @param primaryAccount The account that owns the position.
  /// @param subAccountId The sub account ID of the given account.
  /// @param collateralToken The collateral token.
  /// @param indexToken The index token.
  /// @param sizeDelta The size delta in USD units with 1e30 precision.
  /// @param exposure The exposure that the position is in. Either Long or Short.
  function increasePosition(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 sizeDelta,
    Exposure exposure
  ) external nonReentrant allowed(primaryAccount) {
    if (!config.isLeverageEnable()) revert Pool_LeverageDisabled();
    if (Exposure.LONG == exposure) {
      if (collateralToken != indexToken) revert Pool_BadArgument();
      if (!config.isAcceptToken(collateralToken)) revert Pool_BadArgument();
      if (config.isStableToken(collateralToken)) revert Pool_BadArgument();
    } else {
      if (!config.isAcceptToken(collateralToken)) revert Pool_BadArgument();
      if (!config.isStableToken(collateralToken)) revert Pool_BadArgument();
      if (config.isStableToken(indexToken)) revert Pool_BadArgument();
      if (!config.isShortableToken(indexToken)) revert Pool_BadArgument();
    }
    // TODO: Add validate increase position

    updateFundingRate(collateralToken, indexToken);

    IncreasePositionLocalVars memory vars;

    vars.subAccount = getSubAccount(primaryAccount, subAccountId);

    vars.posId = getPositionId(
      vars.subAccount,
      collateralToken,
      indexToken,
      exposure
    );
    Position storage position = positions[vars.posId];

    vars.price = exposure == Exposure.LONG
      ? oracle.getMaxPrice(collateralToken)
      : oracle.getMinPrice(collateralToken);

    if (position.size == 0) {
      // If position size = 0, then it is a new position.
      // So make average price to equal to price.
      position.averagePrice = vars.price;
    }

    if (position.size > 0 && sizeDelta > 0) {
      // If position size > 0, then position is existed.
      // Need to calculate the next average price.
      position.averagePrice = getNextAveragePrice(
        indexToken,
        position.size,
        position.averagePrice,
        exposure,
        vars.price,
        sizeDelta,
        position.lastIncreasedTime
      );
    }

    vars.feeUsd = _collectMarginFee(
      vars.subAccount,
      collateralToken,
      indexToken,
      exposure,
      sizeDelta,
      position.size,
      position.entryFundingRate
    );
    vars.collateralDelta = _pullTokens(collateralToken);
    vars.collateralDeltaUsd = _convertTokensToUsde30(
      collateralToken,
      vars.collateralDelta,
      MinMax.MIN
    );

    position.collateral += vars.collateralDeltaUsd;
    if (position.collateral < vars.feeUsd) revert Pool_CollateralTooSmall();

    position.collateral -= vars.feeUsd;
    position.entryFundingRate = poolMath.getEntryFundingRate(
      Pool(address(this)),
      collateralToken,
      indexToken,
      exposure
    );
    position.size += sizeDelta;
    position.lastIncreasedTime = block.timestamp;

    if (position.size == 0) revert Pool_BadPositionSize();
    _checkPosition(position.size, position.collateral);
    checkLiquidation(
      vars.subAccount,
      collateralToken,
      indexToken,
      exposure,
      true
    );

    // Lock tokens in reserved to pay for profits on this position.
    uint256 reserveDelta = _convertUsde30ToTokens(
      collateralToken,
      sizeDelta,
      MinMax.MAX
    );
    position.reserveAmount += reserveDelta;
    _increaseReserved(collateralToken, reserveDelta);

    if (Exposure.LONG == exposure) {
      // guaranteedUsd stores the sum of (position.size - position.collateral) for all positions
      // if a fee is charged on the collateral then guaranteedUsd should be increased by that fee amount
      // since (position.size - position.collateral) would have increased by `fee`
      _increaseGuaranteedUsd(collateralToken, sizeDelta + vars.feeUsd);
      _decreaseGuaranteedUsd(collateralToken, vars.collateralDeltaUsd);

      // treat the deposited collateral as part of the pool
      _increasePoolLiquidity(collateralToken, vars.collateralDelta);

      // fees need to be deducted from the pool since fees are deducted from position.collateral
      // and collateral is treated as part of the pool
      _decreasePoolLiquidity(
        collateralToken,
        _convertUsde30ToTokens(collateralToken, vars.feeUsd, MinMax.MIN)
      );
    } else {
      if (shortSizeOf[indexToken] == 0)
        shortAveragePriceOf[indexToken] = vars.price;
      else
        shortAveragePriceOf[indexToken] = getNextShortAveragePrice(
          indexToken,
          vars.price,
          sizeDelta
        );

      _increaseShortSize(indexToken, sizeDelta);
    }

    emit IncreasePosition(
      vars.posId,
      vars.subAccount,
      collateralToken,
      indexToken,
      vars.collateralDeltaUsd,
      sizeDelta,
      exposure,
      vars.price,
      vars.feeUsd
    );
    emit UpdatePosition(
      vars.posId,
      position.size,
      position.collateral,
      position.averagePrice,
      position.entryFundingRate,
      position.reserveAmount,
      position.realizedPnl,
      vars.price
    );
  }

  function _updatePoolLiquidityIncreasePosition(
    address collateralToken,
    address indexToken,
    uint256 price,
    uint256 sizeDelta,
    uint256 collateralDelta,
    uint256 collateralDeltaUsd,
    uint256 feeUsd,
    Exposure exposure
  ) internal {
    if (Exposure.LONG == exposure) {
      // guaranteedUsd stores the sum of (position.size - position.collateral) for all positions
      // if a fee is charged on the collateral then guaranteedUsd should be increased by that fee amount
      // since (position.size - position.collateral) would have increased by `fee`
      _increaseGuaranteedUsd(collateralToken, sizeDelta + feeUsd);
      _decreaseGuaranteedUsd(collateralToken, collateralDeltaUsd);

      // treat the deposited collateral as part of the pool
      _increasePoolLiquidity(collateralToken, collateralDelta);

      // fees need to be deducted from the pool since fees are deducted from position.collateral
      // and collateral is treated as part of the pool
      _decreasePoolLiquidity(
        collateralToken,
        _convertUsde30ToTokens(collateralToken, feeUsd, MinMax.MIN)
      );
    } else {
      if (shortSizeOf[indexToken] == 0) shortAveragePriceOf[indexToken] = price;
      else
        shortAveragePriceOf[indexToken] = getNextShortAveragePrice(
          indexToken,
          price,
          sizeDelta
        );

      _increaseShortSize(indexToken, sizeDelta);
    }
  }

  // ----------------
  // Getter functions
  // ----------------
  function getDelta(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    Exposure exposure,
    uint256 lastIncreasedTime
  ) public view returns (bool, uint256) {
    if (averagePrice == 0) revert Pool_BadArgument();
    uint256 price = Exposure.LONG == exposure
      ? oracle.getMinPrice(indexToken)
      : oracle.getMaxPrice(indexToken);
    uint256 priceDelta;
    unchecked {
      priceDelta = averagePrice > price
        ? averagePrice - price
        : price - averagePrice;
    }
    uint256 delta = (size * priceDelta) / averagePrice;

    bool isProfit;
    if (Exposure.LONG == exposure) {
      isProfit = price > averagePrice;
    } else {
      isProfit = price < averagePrice;
    }

    uint256 minBps = block.timestamp >
      lastIncreasedTime + config.minProfitDuration()
      ? 0
      : config.tokenMinProfitBps(indexToken);
    if (isProfit && delta * BPS <= size * minBps) delta = 0;

    return (isProfit, delta);
  }

  function getNextAveragePrice(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    Exposure exposure,
    uint256 nextPrice,
    uint256 sizeDelta,
    uint256 lastIncreasedTime
  ) public view returns (uint256) {
    (bool isProfit, uint256 delta) = getDelta(
      indexToken,
      size,
      averagePrice,
      exposure,
      lastIncreasedTime
    );
    uint256 nextSize = size + sizeDelta;
    uint256 divisor;
    if (exposure == Exposure.LONG) {
      divisor = isProfit ? nextSize + delta : nextSize - delta;
    } else {
      divisor = isProfit ? nextSize - delta : nextSize + delta;
    }

    return (nextPrice * nextSize) / divisor;
  }

  function getNextFundingRate(address token) public view returns (uint256) {
    // SLOAD
    uint256 fundingInterval = config.fundingInterval();

    // If block.timestamp not pass the next funding time, return 0.
    if (lastFundingTimeOf[token] + fundingInterval > block.timestamp) return 0;

    uint256 intervals;
    unchecked {
      intervals = block.timestamp - lastFundingTimeOf[token] / fundingInterval;
    }
    // SLOAD
    uint256 liquidity = liquidityOf[token];
    if (liquidity == 0) return 0;

    uint256 fundingRateFactor = config.isStableToken(token)
      ? config.stableFundingRateFactor()
      : config.fundingRateFactor();

    return (fundingRateFactor * reservedOf[token] * intervals) / liquidity;
  }

  function getNextShortAveragePrice(
    address indexToken,
    uint256 nextPrice,
    uint256 sizeDelta
  ) public view returns (uint256) {
    uint256 shortSize = shortSizeOf[indexToken];
    uint256 shortAveragePrice = shortAveragePriceOf[indexToken];
    uint256 priceDelta = shortAveragePrice > nextPrice
      ? shortAveragePrice - nextPrice
      : nextPrice - shortAveragePrice;
    uint256 delta = (shortSize * priceDelta) / shortAveragePrice;
    bool isProfit = nextPrice < shortAveragePrice;

    uint256 nextSize = shortSize + sizeDelta;
    uint256 divisor = isProfit ? nextSize - delta : nextSize + delta;

    return (nextPrice * nextSize) / divisor;
  }

  function getPosition(
    address account,
    address collateralToken,
    address indexToken,
    Exposure exposure
  ) public view returns (Position memory) {
    return
      positions[getPositionId(account, collateralToken, indexToken, exposure)];
  }

  function getPositionId(
    address account,
    address collateralToken,
    address indexToken,
    Exposure exposure
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(account, collateralToken, indexToken, exposure)
      );
  }

  function getSubAccount(address primary, uint256 subAccountId)
    public
    pure
    returns (address)
  {
    if (subAccountId > 255) revert Pool_BadArgument();
    return address(uint160(primary) ^ uint160(subAccountId));
  }

  function isSubAccountOf(address primary, address subAccount)
    public
    pure
    returns (bool)
  {
    return (uint160(primary) | 0xFF) == (uint160(subAccount) | 0xFF);
  }

  // ------------------------
  // Fee Collection functions
  // ------------------------

  function _collectMarginFee(
    address account,
    address collateralToken,
    address indexToken,
    Exposure exposure,
    uint256 sizeDelta,
    uint256 size,
    uint256 entryFundingRate
  ) internal returns (uint256) {
    uint256 feeUsd = poolMath.getPositionFee(
      Pool(address(this)),
      account,
      collateralToken,
      indexToken,
      exposure,
      sizeDelta
    );

    uint256 fundingFeeUsd = poolMath.getFundingFee(
      Pool(address(this)),
      account,
      collateralToken,
      indexToken,
      exposure,
      size,
      entryFundingRate
    );

    feeUsd += fundingFeeUsd;

    uint256 feeTokens = _convertUsde30ToTokens(
      collateralToken,
      feeUsd,
      MinMax.MIN
    );
    feeReserveOf[collateralToken] += feeTokens;

    emit CollectMarginFee(collateralToken, feeUsd, feeTokens);

    return feeUsd;
  }

  function _collectSwapFee(
    address token,
    uint256 tokenPriceUsd,
    uint256 amount,
    uint256 feeBps
  ) internal returns (uint256) {
    uint256 fee = (amount * feeBps) / BPS;
    uint256 amountAfterFee = amount - fee;
    feeReserveOf[token] += fee;

    emit CollectSwapFee(token, fee * tokenPriceUsd, fee);

    return amountAfterFee;
  }

  // ------------------------------
  // Liquidity alteration functions
  // ------------------------------

  function _increasePoolLiquidity(address token, uint256 amount) internal {
    liquidityOf[token] += amount;
    if (IERC20(token).balanceOf(address(this)) < liquidityOf[token])
      revert Pool_LiquidityMismatch();
    emit IncreasePoolLiquidity(token, amount);
  }

  function _decreasePoolLiquidity(address token, uint256 amount) internal {
    liquidityOf[token] -= amount;
    if (liquidityOf[token] < reservedOf[token])
      revert Pool_InsufficientLiquidity();
    emit DecreasePoolLiquidity(token, amount);
  }

  function _increaseUsdDebt(address token, uint256 amount) internal {
    usdDebtOf[token] += amount;

    // SLOAD
    uint256 newUsdDebt = usdDebtOf[token];
    uint256 usdDebtCeiling = config.tokenUsdDebtCeiling(token);

    if (usdDebtCeiling != 0) {
      if (newUsdDebt > usdDebtCeiling) revert Pool_OverUsdDebtCeiling();
    }

    emit IncreaseUsdDebt(token, amount);
  }

  function _decreaseUsdDebt(address token, uint256 amount) internal {
    uint256 usdDebt = usdDebtOf[token];
    if (usdDebt <= amount) {
      usdDebtOf[token] = 0;
      emit DecreaseUsdDebt(token, usdDebt);
      return;
    }

    usdDebtOf[token] = usdDebt - amount;

    emit DecreaseUsdDebt(token, amount);
  }

  function _increaseReserved(address token, uint256 amount) internal {
    reservedOf[token] += amount;
    if (reservedOf[token] > liquidityOf[token])
      revert Pool_InsufficientLiquidity();
    emit IncreaseReserved(token, amount);
  }

  function _decreaseReserved(address token, uint256 amount) internal {
    reservedOf[token] -= amount;
    emit DecreaseReserved(token, amount);
  }

  function _increaseGuaranteedUsd(address token, uint256 amountUsd) internal {
    guaranteedUsdOf[token] += amountUsd;
    emit IncreaseGuaranteedUsd(token, amountUsd);
  }

  function _decreaseGuaranteedUsd(address token, uint256 amountUsd) internal {
    guaranteedUsdOf[token] -= amountUsd;
    emit DecreaseGuaranteedUsd(token, amountUsd);
  }

  function _increaseShortSize(address token, uint256 amountUsd) internal {
    // SLOAD
    uint256 shortCeiling = config.tokenShortCeiling(token);
    shortSizeOf[token] += amountUsd;

    if (shortCeiling != 0) {
      if (shortSizeOf[token] > shortCeiling) revert Pool_OverShortCeiling();
    }

    emit IncreaseShortSize(token, amountUsd);
  }

  function _decreaseShortSize(address token, uint256 amountUsd) internal {
    uint256 shortSize = shortSizeOf[token];
    if (amountUsd > shortSize) {
      shortSizeOf[token] = 0;
      return;
    }

    shortSizeOf[token] -= amountUsd;

    emit DecreaseShortSize(token, amountUsd);
  }

  function targetValue(address token) public view returns (uint256) {
    // SLOAD
    uint256 cachedTotalUsdDebt = totalUsdDebt;
    if (cachedTotalUsdDebt == 0) return 0;

    return
      (cachedTotalUsdDebt * config.tokenWeight(token)) /
      config.totalTokenWeight();
  }

  /// ---------------
  /// Check functions
  /// ---------------

  function _checkPosition(uint256 size, uint256 collateral) internal pure {
    if (size == 0) {
      if (collateral != 0) revert Pool_FailCheckPosition();
      return;
    }
    if (size < collateral) revert Pool_FailCheckPosition();
  }

  function checkLiquidation(
    address account,
    address collateralToken,
    address indexToken,
    Exposure exposure,
    bool isRevertWhenError
  ) public view returns (uint256, uint256) {
    return
      poolMath.checkLiquidation(
        Pool(address(this)),
        account,
        collateralToken,
        indexToken,
        exposure,
        isRevertWhenError
      );
  }

  /// --------------------
  /// Conversion functions
  /// --------------------

  /// @notice Convert decimals
  function _convertTokenDecimals(
    uint256 fromTokenDecimals,
    uint256 toTokenDecimals,
    uint256 amount
  ) internal pure returns (uint256) {
    return (amount * 10**toTokenDecimals) / 10**fromTokenDecimals;
  }

  function _convertUsde30ToTokens(
    address token,
    uint256 amountUsd,
    MinMax minOrMax
  ) internal view returns (uint256) {
    if (amountUsd == 0) return 0;
    return
      (amountUsd * (10**config.tokenDecimals(token))) /
      oracle.getPrice(token, minOrMax);
  }

  function _convertTokensToUsde30(
    address token,
    uint256 amountTokens,
    MinMax minOrMax
  ) internal view returns (uint256) {
    if (amountTokens == 0) return 0;
    return
      (amountTokens * oracle.getPrice(token, minOrMax)) /
      (10**config.tokenDecimals(token));
  }

  function _pullTokens(address token) internal returns (uint256) {
    uint256 prevBalance = totalOf[token];
    uint256 nextBalance = IERC20(token).balanceOf(address(this));

    totalOf[token] = nextBalance;

    return nextBalance - prevBalance;
  }

  function _pushTokens(
    address token,
    address to,
    uint256 amount
  ) internal {
    IERC20(token).safeTransfer(to, amount);
    totalOf[token] = IERC20(token).balanceOf(address(this));
  }
}
