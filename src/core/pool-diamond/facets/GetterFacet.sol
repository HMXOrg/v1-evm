// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { LibPoolV1 } from "../libraries/LibPoolV1.sol";

import { GetterFacetInterface } from "../interfaces/GetterFacetInterface.sol";
import { MintableTokenInterface } from "../../../interfaces/MintableTokenInterface.sol";

contract GetterFacet is GetterFacetInterface {
  enum Exposure {
    LONG,
    SHORT
  }

  enum MinMax {
    MIN,
    MAX
  }

  enum LiquidationState {
    HEALTHY,
    SOFT_LIQUIDATE,
    LIQUIDATE
  }

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
  function plp() external view returns (MintableTokenInterface) {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();
    return poolV1ds.plp;
  }

  function lastAddLiquidityAtOf(address user) external view returns (uint256) {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();
    return poolV1ds.lastAddLiquidityAtOf[user];
  }

  function totalUsdDebt() external view returns (uint256) {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();
    return poolV1ds.totalUsdDebt;
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
