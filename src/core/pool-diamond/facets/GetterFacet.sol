// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig } from "../../PoolConfig.sol";
import { PoolOracle } from "../../PoolOracle.sol";
import { LibPoolV1 } from "../libraries/LibPoolV1.sol";

import { GetterFacetInterface } from "../interfaces/GetterFacetInterface.sol";
import { MintableTokenInterface } from "../../../interfaces/MintableTokenInterface.sol";

contract GetterFacet is GetterFacetInterface {
  error GetterFacet_BadSubAccountId();
  error GetterFacet_InvalidAveragePrice();

  enum LiquidityDirection {
    ADD,
    REMOVE
  }

  address internal constant LINKEDLIST_START = address(1);
  address internal constant LINKEDLIST_END = address(1);
  address internal constant LINKEDLIST_EMPTY = address(0);

  uint256 internal constant PRICE_PRECISION = 10**30;
  uint256 internal constant FUNDING_RATE_PRECISION = 1000000;
  uint256 internal constant BPS = 10000;
  uint256 internal constant USD_DECIMALS = 18;

  // ---------------------------
  // Simple info functions
  // ---------------------------
  function additionalAum() external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().additionalAum;
  }

  function approvedPlugins(address user, address plugin)
    external
    view
    returns (bool)
  {
    return LibPoolV1.poolV1DiamondStorage().approvedPlugins[user][plugin];
  }

  function config() external view returns (PoolConfig) {
    return LibPoolV1.poolV1DiamondStorage().config;
  }

  function discountedAum() external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().discountedAum;
  }

  function feeReserveOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().feeReserveOf[token];
  }

  function guaranteedUsdOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().guaranteedUsdOf[token];
  }

  function lastAddLiquidityAtOf(address user) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().lastAddLiquidityAtOf[user];
  }

  function lastFundingTimeOf(address user) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().lastFundingTimeOf[user];
  }

  function liquidityOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().liquidityOf[token];
  }

  function oracle() external view returns (PoolOracle) {
    return LibPoolV1.poolV1DiamondStorage().oracle;
  }

  function plp() external view returns (MintableTokenInterface) {
    return LibPoolV1.poolV1DiamondStorage().plp;
  }

  function reservedOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().reservedOf[token];
  }

  function shortSizeOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().shortSizeOf[token];
  }

  function shortAveragePriceOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().shortAveragePriceOf[token];
  }

  function sumFundingRateOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().sumFundingRateOf[token];
  }

  function totalOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().totalOf[token];
  }

  function totalUsdDebt() external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().totalUsdDebt;
  }

  function usdDebtOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().usdDebtOf[token];
  }

  function getDelta(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 lastIncreasedTime
  ) public view returns (bool, uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    if (averagePrice == 0) revert GetterFacet_InvalidAveragePrice();
    uint256 price = isLong
      ? ds.oracle.getMinPrice(indexToken)
      : ds.oracle.getMaxPrice(indexToken);
    uint256 priceDelta;
    unchecked {
      priceDelta = averagePrice > price
        ? averagePrice - price
        : price - averagePrice;
    }
    uint256 delta = (size * priceDelta) / averagePrice;

    bool isProfit;
    if (isLong) {
      isProfit = price > averagePrice;
    } else {
      isProfit = price < averagePrice;
    }

    uint256 minBps = block.timestamp >
      lastIncreasedTime + ds.config.minProfitDuration()
      ? 0
      : ds.config.getTokenMinProfitBpsOf(indexToken);

    if (isProfit && delta * BPS <= size * minBps) delta = 0;

    return (isProfit, delta);
  }

  function getEntryFundingRate(
    address collateralToken,
    address, /* indexToken */
    bool /* isLong */
  ) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().sumFundingRateOf[collateralToken];
  }

  function getFundingFee(
    address, /* account */
    address collateralToken,
    address, /* indexToken */
    bool, /* isLong */
    uint256 size,
    uint256 entryFundingRate
  ) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    if (size == 0) return 0;

    uint256 fundingRate = ds.sumFundingRateOf[collateralToken] -
      entryFundingRate;
    if (fundingRate == 0) return 0;

    return (size * fundingRate) / FUNDING_RATE_PRECISION;
  }

  function getNextShortAveragePrice(
    address indexToken,
    uint256 nextPrice,
    uint256 sizeDelta
  ) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    uint256 shortSize = ds.shortSizeOf[indexToken];
    uint256 shortAveragePrice = ds.shortAveragePriceOf[indexToken];
    uint256 priceDelta = shortAveragePrice > nextPrice
      ? shortAveragePrice - nextPrice
      : nextPrice - shortAveragePrice;
    uint256 delta = (shortSize * priceDelta) / shortAveragePrice;
    bool isProfit = nextPrice < shortAveragePrice;

    uint256 nextSize = shortSize + sizeDelta;
    uint256 divisor = isProfit ? nextSize - delta : nextSize + delta;

    return (nextPrice * nextSize) / divisor;
  }

  function getPoolShortDelta(address token)
    external
    view
    returns (bool, uint256)
  {
    // Load Diamond Storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    uint256 shortSize = ds.shortSizeOf[token];
    if (shortSize == 0) return (false, 0);

    uint256 nextPrice = ds.oracle.getMaxPrice(token);
    uint256 averagePrice = ds.shortAveragePriceOf[token];
    uint256 priceDelta;
    unchecked {
      priceDelta = averagePrice > nextPrice
        ? averagePrice - nextPrice
        : nextPrice - averagePrice;
    }
    uint256 delta = (shortSize * priceDelta) / averagePrice;

    return (averagePrice > nextPrice, delta);
  }

  function getPositionWithSubAccountId(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (GetPositionReturnVars memory) {
    return
      getPosition(
        getSubAccount(primaryAccount, subAccountId),
        collateralToken,
        indexToken,
        isLong
      );
  }

  function getPosition(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong
  ) public view returns (GetPositionReturnVars memory) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    LibPoolV1.Position memory position = ds.positions[
      LibPoolV1.getPositionId(account, collateralToken, indexToken, isLong)
    ];
    uint256 realizedPnl = position.realizedPnl > 0
      ? uint256(position.realizedPnl)
      : uint256(-position.realizedPnl);
    GetPositionReturnVars memory vars = GetPositionReturnVars({
      primaryAccount: position.primaryAccount,
      size: position.size,
      collateral: position.collateral,
      averagePrice: position.averagePrice,
      entryFundingRate: position.entryFundingRate,
      reserveAmount: position.reserveAmount,
      realizedPnl: realizedPnl,
      hasProfit: position.realizedPnl >= 0,
      lastIncreasedTime: position.lastIncreasedTime
    });
    return vars;
  }

  function getPositionDelta(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (bool, uint256) {
    LibPoolV1.Position memory position = LibPoolV1
      .poolV1DiamondStorage()
      .positions[
        LibPoolV1.getPositionId(
          LibPoolV1.getSubAccount(primaryAccount, subAccountId),
          collateralToken,
          indexToken,
          isLong
        )
      ];
    return
      getDelta(
        indexToken,
        position.size,
        position.averagePrice,
        isLong,
        position.lastIncreasedTime
      );
  }

  function getPositionFee(
    address, /* account */
    address, /* collateralToken */
    address, /* indexToken */
    bool, /* isLong */
    uint256 sizeDelta
  ) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    if (sizeDelta == 0) return 0;
    uint256 afterFeeUsd = (sizeDelta * (BPS - ds.config.positionFeeBps())) /
      BPS;
    return sizeDelta - afterFeeUsd;
  }

  function getPositionLeverage(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (uint256) {
    bytes32 posId = LibPoolV1.getPositionId(
      LibPoolV1.getSubAccount(primaryAccount, subAccountId),
      collateralToken,
      indexToken,
      isLong
    );
    LibPoolV1.Position memory position = LibPoolV1
      .poolV1DiamondStorage()
      .positions[posId];
    return (position.size * BPS) / position.collateral;
  }

  function getPositionNextAveragePrice(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 nextPrice,
    uint256 sizeDelta,
    uint256 lastIncreasedTime
  ) external view returns (uint256) {
    (bool isProfit, uint256 delta) = getDelta(
      indexToken,
      size,
      averagePrice,
      isLong,
      lastIncreasedTime
    );
    uint256 nextSize = size + sizeDelta;
    uint256 divisor;
    if (isLong) {
      divisor = isProfit ? nextSize + delta : nextSize - delta;
    } else {
      divisor = isProfit ? nextSize - delta : nextSize + delta;
    }

    return (nextPrice * nextSize) / divisor;
  }

  function getRedemptionCollateral(address token)
    public
    view
    returns (uint256)
  {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    if (ds.config.isStableToken(token)) return ds.liquidityOf[token];

    uint256 collateral = LibPoolV1.convertUsde30ToTokens(
      token,
      ds.guaranteedUsdOf[token],
      true
    );
    return collateral + ds.liquidityOf[token] - ds.reservedOf[token];
  }

  function getRedemptionCollateralUsd(address token)
    external
    view
    returns (uint256)
  {
    return
      LibPoolV1.convertTokensToUsde30(
        token,
        getRedemptionCollateral(token),
        false
      );
  }

  function getSubAccount(address primary, uint256 subAccountId)
    public
    pure
    returns (address)
  {
    return LibPoolV1.getSubAccount(primary, subAccountId);
  }

  function getTargetValue(address token) public view returns (uint256) {
    // SLOAD
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();
    uint256 cachedTotalUsdDebt = poolV1ds.totalUsdDebt;

    if (cachedTotalUsdDebt == 0) return 0;

    return
      (cachedTotalUsdDebt * poolV1ds.config.getTokenWeightOf(token)) /
      poolV1ds.config.totalTokenWeight();
  }

  // ---------------------------
  // Asset under management math
  // ---------------------------

  function getAum(bool isUseMaxPrice) public view returns (uint256) {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    address token = poolV1ds.config.getNextAllowTokenOf(LINKEDLIST_START);
    uint256 aum = poolV1ds.additionalAum;
    uint256 shortProfits = 0;

    while (token != LINKEDLIST_END) {
      uint256 price = !isUseMaxPrice
        ? poolV1ds.oracle.getMinPrice(token)
        : poolV1ds.oracle.getMaxPrice(token);
      uint256 liquidity = poolV1ds.liquidityOf[token];
      uint256 decimals = poolV1ds.config.getTokenDecimalsOf(token);

      if (poolV1ds.config.isStableToken(token)) {
        aum += (liquidity * price) / 10**decimals;
      } else {
        uint256 shortSize = poolV1ds.shortSizeOf[token];
        if (shortSize > 0) {
          uint256 shortAveragePrice = poolV1ds.shortAveragePriceOf[token];
          uint256 priceDelta;
          unchecked {
            priceDelta = shortAveragePrice > price
              ? shortAveragePrice - price
              : price - shortAveragePrice;
          }
          // Findout delta (can be either profit or loss) of short positions.
          uint256 delta = (shortSize * priceDelta) / shortAveragePrice;

          if (price > shortAveragePrice) {
            // Short position is at loss, then count it as aum
            aum += delta;
          } else {
            // Short position is at profit, then count it as shortProfits
            shortProfits += delta;
          }
        }

        // Add guaranteed USD to the aum.
        aum += poolV1ds.guaranteedUsdOf[token];

        // Add actual liquidity of the token to the aum.
        aum +=
          ((liquidity - poolV1ds.reservedOf[token]) * price) /
          10**decimals;
      }

      token = poolV1ds.config.getNextAllowTokenOf(token);
    }

    aum = shortProfits > aum ? 0 : aum - shortProfits;
    return poolV1ds.discountedAum > aum ? 0 : aum - poolV1ds.discountedAum;
  }

  function getAumE18(bool isUseMaxPrice) external view returns (uint256) {
    return (getAum(isUseMaxPrice) * 10**18) / PRICE_PRECISION;
  }

  // ------------------------
  // Delta Liquidity Fee Math
  // ------------------------

  function getFeeBps(
    address token,
    uint256 value,
    uint256 feeBps,
    uint256 taxBps,
    LiquidityDirection direction
  ) internal view returns (uint256) {
    // Load PoolV1 Diamond Storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    if (!poolV1ds.config.isDynamicFeeEnable()) return feeBps;

    uint256 startValue = poolV1ds.usdDebtOf[token];
    uint256 nextValue = startValue + value;
    if (direction == LiquidityDirection.REMOVE)
      nextValue = value > startValue ? 0 : startValue - value;

    uint256 targetValue = getTargetValue(token);
    if (targetValue == 0) return feeBps;

    uint256 startTargetDiff = startValue > targetValue
      ? startValue - targetValue
      : targetValue - startValue;
    uint256 nextTargetDiff = nextValue > targetValue
      ? nextValue - targetValue
      : targetValue - nextValue;

    // nextValue moves closer to the targetValue -> positive case;
    // Should apply rebate.
    if (nextTargetDiff < startTargetDiff) {
      uint256 rebateBps = (taxBps * startTargetDiff) / targetValue;
      return rebateBps > feeBps ? 0 : feeBps - rebateBps;
    }

    // If not then -> negative impact to the pool.
    // Should apply tax.
    uint256 midDiff = (startTargetDiff + nextTargetDiff) / 2;
    if (midDiff > targetValue) {
      midDiff = targetValue;
    }
    taxBps = (taxBps * midDiff) / targetValue;

    return feeBps + taxBps;
  }

  function getAddLiquidityFeeBps(address token, uint256 value)
    external
    view
    returns (uint256)
  {
    // Load PoolV1 Diamond Storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    return
      getFeeBps(
        token,
        value,
        poolV1ds.config.mintBurnFeeBps(),
        poolV1ds.config.taxBps(),
        LiquidityDirection.ADD
      );
  }

  function getRemoveLiquidityFeeBps(address token, uint256 value)
    external
    view
    returns (uint256)
  {
    // Load PoolV1 Diamond Storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    return
      getFeeBps(
        token,
        value,
        poolV1ds.config.mintBurnFeeBps(),
        poolV1ds.config.taxBps(),
        LiquidityDirection.REMOVE
      );
  }

  function getSwapFeeBps(
    address tokenIn,
    address tokenOut,
    uint256 usdDebt
  ) external view returns (uint256) {
    // Load PoolV1 Diamond Storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    bool isStableSwap = poolV1ds.config.isStableToken(tokenIn) &&
      poolV1ds.config.isStableToken(tokenOut);
    uint64 baseFeeBps = isStableSwap
      ? poolV1ds.config.stableSwapFeeBps()
      : poolV1ds.config.swapFeeBps();
    uint64 taxBps = isStableSwap
      ? poolV1ds.config.stableTaxBps()
      : poolV1ds.config.taxBps();
    uint256 feeBpsIn = getFeeBps(
      tokenIn,
      usdDebt,
      baseFeeBps,
      taxBps,
      LiquidityDirection.ADD
    );
    uint256 feeBpsOut = getFeeBps(
      tokenOut,
      usdDebt,
      baseFeeBps,
      taxBps,
      LiquidityDirection.REMOVE
    );

    // Return the highest feeBps.
    return feeBpsIn > feeBpsOut ? feeBpsIn : feeBpsOut;
  }

  // ------------
  // Funding rate
  // ------------

  function getNextFundingRate(address token) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();
    uint256 fundingInterval = poolV1ds.config.fundingInterval();

    // If block.timestamp not pass the next funding time, return 0.
    if (poolV1ds.lastFundingTimeOf[token] + fundingInterval > block.timestamp)
      return 0;

    uint256 intervals = (block.timestamp - poolV1ds.lastFundingTimeOf[token]) /
      fundingInterval;
    // SLOAD
    uint256 liquidity = poolV1ds.liquidityOf[token];
    if (liquidity == 0) return 0;

    uint256 fundingRateFactor = poolV1ds.config.isStableToken(token)
      ? poolV1ds.config.stableFundingRateFactor()
      : poolV1ds.config.fundingRateFactor();

    return
      (fundingRateFactor * poolV1ds.reservedOf[token] * intervals) / liquidity;
  }
}