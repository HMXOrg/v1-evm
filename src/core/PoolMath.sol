// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Pool } from "./Pool.sol";
import { Constants } from "./Constants.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { console } from "../tests/utils/console.sol";

contract PoolMath is Constants {
  error PoolMath_FeeExceedCollateral();
  error PoolMath_LiquidationFeeExceedCollateral();
  error PoolMath_LossesExceedCollateral();
  error PoolMath_MaxLeverageExceed();

  enum LiquidityDirection {
    ADD,
    REMOVE
  }

  // ---------------------------
  // Asset under management math
  // ---------------------------

  function getAum(Pool pool, MinMax minOrMax) public view returns (uint256) {
    address token = pool.config().getNextAllowTokenOf(LINKEDLIST_START);
    uint256 aum = pool.additionalAum();
    uint256 shortProfits = 0;

    while (token != LINKEDLIST_END) {
      uint256 price = minOrMax == MinMax.MIN
        ? pool.oracle().getMinPrice(token)
        : pool.oracle().getMaxPrice(token);
      uint256 liquidity = pool.liquidityOf(token);
      uint256 decimals = pool.config().getTokenDecimalsOf(token);

      if (pool.config().isStableToken(token)) {
        aum += (liquidity * price) / 10**decimals;
      } else {
        uint256 shortSize = pool.shortSizeOf(token);
        if (shortSize > 0) {
          uint256 shortAveragePrice = pool.shortAveragePriceOf(token);
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
        aum += pool.guaranteedUsdOf(token);

        // Add actual liquidity of the token to the aum.
        aum += ((liquidity - pool.reservedOf(token)) * price) / 10**decimals;
      }

      token = pool.config().getNextAllowTokenOf(token);
    }

    aum = shortProfits > aum ? 0 : aum - shortProfits;
    return pool.discountedAum() > aum ? 0 : aum - pool.discountedAum();
  }

  function getAum18(Pool pool, MinMax minOrMax)
    external
    view
    returns (uint256)
  {
    return (getAum(pool, minOrMax) * 10**18) / PRICE_PRECISION;
  }

  // ------------------------
  // Delta Liquidity Fee Math
  // ------------------------

  function getFeeBps(
    Pool pool,
    address token,
    uint256 value,
    uint256 feeBps,
    uint256 taxBps,
    LiquidityDirection direction
  ) internal view returns (uint256) {
    if (!pool.config().isDynamicFeeEnable()) return feeBps;

    uint256 startValue = pool.usdDebtOf(token);
    uint256 nextValue = startValue + value;
    if (direction == LiquidityDirection.REMOVE)
      nextValue = value > startValue ? 0 : startValue - value;

    uint256 targetValue = pool.getTargetValue(token);
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

  function getAddLiquidityFeeBps(
    Pool pool,
    address token,
    uint256 value
  ) external view returns (uint256) {
    return
      getFeeBps(
        pool,
        token,
        value,
        pool.config().mintBurnFeeBps(),
        pool.config().taxBps(),
        LiquidityDirection.ADD
      );
  }

  function getRemoveLiquidityFeeBps(
    Pool pool,
    address token,
    uint256 value
  ) external view returns (uint256) {
    return
      getFeeBps(
        pool,
        token,
        value,
        pool.config().mintBurnFeeBps(),
        pool.config().taxBps(),
        LiquidityDirection.REMOVE
      );
  }

  function getSwapFeeBps(
    Pool pool,
    address tokenIn,
    address tokenOut,
    uint256 usdDebt
  ) external view returns (uint256) {
    bool isStableSwap = pool.config().isStableToken(tokenIn) &&
      pool.config().isStableToken(tokenOut);
    uint64 baseFeeBps = isStableSwap
      ? pool.config().stableSwapFeeBps()
      : pool.config().swapFeeBps();
    uint64 taxBps = isStableSwap
      ? pool.config().stableTaxBps()
      : pool.config().taxBps();
    uint256 feeBpsIn = getFeeBps(
      pool,
      tokenIn,
      usdDebt,
      baseFeeBps,
      taxBps,
      LiquidityDirection.ADD
    );
    uint256 feeBpsOut = getFeeBps(
      pool,
      tokenOut,
      usdDebt,
      baseFeeBps,
      taxBps,
      LiquidityDirection.REMOVE
    );

    // Return the highest feeBps.
    return feeBpsIn > feeBpsOut ? feeBpsIn : feeBpsOut;
  }

  // ---------------
  // Margin Fee Math
  // ---------------

  function getEntryFundingRate(
    Pool pool,
    address collateralToken,
    address, /* indexToken */
    Exposure /* exposure */
  ) external view returns (uint256) {
    return pool.sumFundingRateOf(collateralToken);
  }

  function getFundingFee(
    Pool pool,
    address, /* account */
    address collateralToken,
    address, /* indexToken */
    Exposure, /* exposure */
    uint256 size,
    uint256 entryFundingRate
  ) public view returns (uint256) {
    if (size == 0) return 0;

    uint256 fundingRate = pool.sumFundingRateOf(collateralToken) -
      entryFundingRate;
    if (fundingRate == 0) return 0;

    return (size * fundingRate) / FUNDING_RATE_PRECISION;
  }

  function getPositionFee(
    Pool pool,
    address, /* account */
    address, /* collateralToken */
    address, /* indexToken */
    Exposure, /* exposure */
    uint256 sizeDelta
  ) public view returns (uint256) {
    if (sizeDelta == 0) return 0;
    uint256 afterFeeUsd = (sizeDelta * (BPS - pool.config().positionFeeBps())) /
      BPS;
    return sizeDelta - afterFeeUsd;
  }

  // ----------------
  // Liquidation Math
  // ----------------
  function checkLiquidation(
    Pool pool,
    address account,
    address collateralToken,
    address indexToken,
    Exposure exposure,
    bool isRevertOnError
  ) external view returns (LiquidationState, uint256) {
    Pool.GetPositionReturnVars memory position = pool.getPosition(
      account,
      collateralToken,
      indexToken,
      exposure
    );

    (bool isProfit, uint256 delta) = pool.getDelta(
      indexToken,
      position.size,
      position.averagePrice,
      exposure,
      position.lastIncreasedTime
    );
    uint256 marginFee = getFundingFee(
      pool,
      account,
      collateralToken,
      indexToken,
      exposure,
      position.size,
      position.entryFundingRate
    );
    marginFee += getPositionFee(
      pool,
      account,
      collateralToken,
      indexToken,
      exposure,
      position.size
    );

    if (!isProfit && position.collateral < delta) {
      if (isRevertOnError) revert PoolMath_LossesExceedCollateral();
      return (LiquidationState.LIQUIDATE, marginFee);
    }

    uint256 remainingCollateral = position.collateral;
    if (!isProfit) {
      remainingCollateral -= delta;
    }

    if (remainingCollateral < marginFee) {
      if (isRevertOnError) revert PoolMath_FeeExceedCollateral();
      // Cap the fee to the remainingCollateral.
      return (LiquidationState.LIQUIDATE, remainingCollateral);
    }

    if (remainingCollateral < marginFee + pool.config().liquidationFeeUsd()) {
      if (isRevertOnError) revert PoolMath_LiquidationFeeExceedCollateral();
      // Cap the fee to the margin fee
      return (LiquidationState.LIQUIDATE, marginFee);
    }

    if (
      remainingCollateral * pool.config().maxLeverage() < position.size * BPS
    ) {
      if (isRevertOnError) revert PoolMath_MaxLeverageExceed();
      return (LiquidationState.SOFT_LIQUIDATE, marginFee);
    }

    return (LiquidationState.HEALTHY, marginFee);
  }
}
