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
  error Pool_CoolDown();
  error Pool_LeverageDisabled();
  error Pool_LiquidityBuffer();
  error Pool_LiquidityMismatch();
  error Pool_InsufficientLiquidity();
  error Pool_InsufficientLiquidityMint();
  error Pool_OverUsdDebtCeiling();
  error Pool_Slippage();
  error Pool_SwapDisabled();

  MintableTokenInterface public plp;

  PoolConfig public config;
  PoolMath public poolMath;
  PoolOracle public oracle;

  mapping(address => uint256) public totals;
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
    uint256 collateral;
    uint256 averagePrice;
    uint256 entryFundingRate;
    uint256 reserveAmount;
    int256 realizedPnl;
    uint256 lastIncreasedTime;
  }
  mapping(bytes32 => Position) public positions;

  event AccrueFundingRate(address token, uint256 sumFundingRate);
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
  event DecreasePoolLiquidity(address token, uint256 amount);
  event DecreaseUsdDebt(address token, uint256 amount);
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
  event IncreasePoolLiquidity(address token, uint256 amount);
  event IncreaseUsdDebt(address token, uint256 amount);
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

  function accrueFundingRate(address collateralToken, address indexToken)
    public
  {
    if (!config.shouldAccrueFundingRate(collateralToken, indexToken)) return;

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

    uint256 fundingRate = nextFundingRate(collateralToken);
    unchecked {
      sumFundingRateOf[collateralToken] =
        sumFundingRateOf[collateralToken] +
        fundingRate;
      lastFundingTimeOf[collateralToken] =
        (block.timestamp / fundingInterval) *
        fundingInterval;
    }

    emit AccrueFundingRate(collateralToken, sumFundingRateOf[collateralToken]);
  }

  function addLiquidity(
    address token,
    uint256 amount,
    address receiver,
    uint256 minLiquidity
  ) external nonReentrant returns (uint256) {
    // Check
    if (!config.isAcceptToken(token)) revert Pool_BadArgument();
    if (amount == 0) revert Pool_BadArgument();

    uint256 aum = poolMath.getAum18(Pool(address(this)), MinMax.MAX);
    uint256 lpSupply = plp.totalSupply();

    // Transfer here or ERC777s could re-enter.
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    uint256 usdDebt = _join(token, amount, receiver);
    uint256 mintAmount = aum == 0 ? usdDebt : (usdDebt * lpSupply) / aum;
    if (mintAmount < minLiquidity) revert Pool_Slippage();

    plp.mint(receiver, mintAmount);

    lastAddLiquidityAtOf[msg.sender] = block.timestamp;

    emit AddLiquidity(
      msg.sender,
      token,
      amount,
      aum,
      lpSupply,
      usdDebt,
      mintAmount
    );

    return mintAmount;
  }

  function removeLiquidity(
    address tokenOut,
    uint256 liquidity,
    address receiver,
    uint256 minAmountOut
  ) external nonReentrant returns (uint256) {
    if (!config.isAcceptToken(tokenOut)) revert Pool_BadArgument();
    if (liquidity == 0) revert Pool_BadArgument();
    if (
      lastAddLiquidityAtOf[msg.sender] + config.liquidityCoolDownDuration() >
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
    if (amountOut < minAmountOut) revert Pool_Slippage();

    plp.burn(msg.sender, liquidity);
    IERC20(tokenOut).transfer(receiver, amountOut);

    emit RemoveLiquidity(
      msg.sender,
      tokenOut,
      liquidity,
      aum,
      lpSupply,
      lpUsdValue,
      amountOut
    );

    return amountOut;
  }

  function swap(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    address receiver
  ) external nonReentrant returns (uint256) {
    if (!config.isSwapEnable()) revert Pool_SwapDisabled();
    if (!config.isAcceptToken(tokenIn)) revert Pool_BadArgument();
    if (!config.isAcceptToken(tokenOut)) revert Pool_BadArgument();
    if (tokenIn == tokenOut) revert Pool_BadArgument();
    if (amountIn == 0) revert Pool_BadArgument();

    accrueFundingRate(tokenIn, tokenIn);
    accrueFundingRate(tokenOut, tokenOut);

    // Transfer amount in.
    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

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
    IERC20(tokenOut).transfer(receiver, amountOutAfterFee);

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

  function _increasePosition(
    address account,
    address collateralToken,
    address indexToken,
    uint256 sizeDelta,
    Exposure exposure
  ) internal {
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

    accrueFundingRate(collateralToken, indexToken);

    bytes32 posId = getPositionId(
      account,
      collateralToken,
      indexToken,
      exposure
    );
    Position storage position = positions[posId];

    uint256 price = exposure == Exposure.LONG
      ? oracle.getMaxPrice(collateralToken)
      : oracle.getMinPrice(collateralToken);

    if (position.size == 0) {
      // If position size = 0, then it is a new position.
      // So make average price to equal to price.
      position.averagePrice = price;
    }

    if (position.size > 0 && sizeDelta > 0) {
      // If position size > 0, then position is existed.
      // Need to calculate the next average price.
      position.averagePrice = getNextAveragePrice(
        indexToken,
        position.size,
        position.averagePrice,
        exposure,
        price,
        sizeDelta,
        position.lastIncreasedTime
      );
    }
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

  function _join(
    address token,
    uint256 amount,
    address receiver
  ) internal returns (uint256) {
    accrueFundingRate(token, token);

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

  function _exit(
    address token,
    uint256 usdValue,
    address receiver
  ) internal returns (uint256) {
    accrueFundingRate(token, token);

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

  function mintFeeBps(address token, uint256 tokenValue)
    internal
    view
    returns (uint256)
  {}

  function nextFundingRate(address token) public view returns (uint256) {
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

  function targetValue(address token) public view returns (uint256) {
    // SLOAD
    uint256 cachedTotalUsdDebt = totalUsdDebt;
    if (cachedTotalUsdDebt == 0) return 0;

    return
      (cachedTotalUsdDebt * config.tokenWeight(token)) /
      config.totalTokenWeight();
  }

  /// @notice Convert decimals
  function _convertTokenDecimals(
    uint256 fromTokenDecimals,
    uint256 toTokenDecimals,
    uint256 amount
  ) internal pure returns (uint256) {
    return (amount * 10**toTokenDecimals) / 10**fromTokenDecimals;
  }
}
