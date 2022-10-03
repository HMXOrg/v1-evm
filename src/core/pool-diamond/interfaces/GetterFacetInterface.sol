// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibPoolConfigV1 } from "../libraries/LibPoolConfigV1.sol";
import { PoolOracle } from "../../PoolOracle.sol";
import { PLP } from "../../../tokens/PLP.sol";
import { StrategyInterface } from "../../../interfaces/StrategyInterface.sol";

interface GetterFacetInterface {
  function additionalAum() external view returns (uint256);

  function approvedPlugins(address user, address plugin)
    external
    view
    returns (bool);

  function discountedAum() external view returns (uint256);

  function feeReserveOf(address token) external view returns (uint256);

  function fundingInterval() external view returns (uint64);

  function fundingRateFactor() external view returns (uint64);

  function getStrategyDeltaOf(address token)
    external
    view
    returns (bool, uint256);

  function guaranteedUsdOf(address token) external view returns (uint256);

  function isAllowAllLiquidators() external view returns (bool);

  function isAllowedLiquidators(address liquidator)
    external
    view
    returns (bool);

  function isDynamicFeeEnable() external view returns (bool);

  function isLeverageEnable() external view returns (bool);

  function isSwapEnable() external view returns (bool);

  function lastFundingTimeOf(address token) external view returns (uint256);

  function liquidationFeeUsd() external view returns (uint256);

  function liquidityOf(address token) external view returns (uint256);

  function maxLeverage() external view returns (uint64);

  function minProfitDuration() external view returns (uint64);

  function mintBurnFeeBps() external view returns (uint64);

  function oracle() external view returns (PoolOracle);

  function pendingStrategyOf(address token)
    external
    view
    returns (StrategyInterface);

  function plp() external view returns (PLP);

  function positionFeeBps() external view returns (uint64);

  function reservedOf(address token) external view returns (uint256);

  function router() external view returns (address);

  function shortSizeOf(address token) external view returns (uint256);

  function shortAveragePriceOf(address token) external view returns (uint256);

  function stableFundingRateFactor() external view returns (uint64);

  function stableTaxBps() external view returns (uint64);

  function stableSwapFeeBps() external view returns (uint64);

  function strategyOf(address token) external view returns (StrategyInterface);

  function strategyDataOf(address token)
    external
    view
    returns (LibPoolConfigV1.StrategyData memory);

  function sumFundingRateOf(address token) external view returns (uint256);

  function swapFeeBps() external view returns (uint64);

  function taxBps() external view returns (uint64);

  function totalOf(address token) external view returns (uint256);

  function tokenMetas(address token)
    external
    view
    returns (LibPoolConfigV1.TokenConfig memory);

  function totalTokenWeight() external view returns (uint256);

  function totalUsdDebt() external view returns (uint256);

  function usdDebtOf(address token) external view returns (uint256);

  function getDelta(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 lastIncreasedTime
  ) external view returns (bool, uint256);

  function getEntryFundingRate(
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (uint256);

  function getFundingFee(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong,
    uint256 size,
    uint256 entryFundingRate
  ) external view returns (uint256);

  function getNextShortAveragePrice(
    address indexToken,
    uint256 nextPrice,
    uint256 sizeDelta
  ) external view returns (uint256);

  struct GetPositionReturnVars {
    address primaryAccount;
    uint256 size;
    uint256 collateral;
    uint256 averagePrice;
    uint256 entryFundingRate;
    uint256 reserveAmount;
    uint256 realizedPnl;
    bool hasProfit;
    uint256 lastIncreasedTime;
  }

  function getPoolShortDelta(address token)
    external
    view
    returns (bool, uint256);

  function getPosition(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (GetPositionReturnVars memory);

  function getPositionWithSubAccountId(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (GetPositionReturnVars memory);

  function getPositionDelta(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (bool, uint256);

  function getPositionFee(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong,
    uint256 sizeDelta
  ) external view returns (uint256);

  function getPositionLeverage(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (uint256);

  function getPositionNextAveragePrice(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 nextPrice,
    uint256 sizeDelta,
    uint256 lastIncreasedTime
  ) external view returns (uint256);

  function getRedemptionCollateral(address token)
    external
    view
    returns (uint256);

  function getRedemptionCollateralUsd(address token)
    external
    view
    returns (uint256);

  function getSubAccount(address primaryAccount, uint256 subAccountId)
    external
    pure
    returns (address);

  function getTargetValue(address token) external view returns (uint256);

  function getAddLiquidityFeeBps(address token, uint256 value)
    external
    view
    returns (uint256);

  function getAum(bool isUseMaxPrice) external view returns (uint256);

  function getAumE18(bool isUseMaxPrice) external view returns (uint256);

  function getRemoveLiquidityFeeBps(address token, uint256 value)
    external
    view
    returns (uint256);

  function getSwapFeeBps(
    address tokenIn,
    address tokenOut,
    uint256 usdDebt
  ) external view returns (uint256);

  function getNextFundingRate(address token) external view returns (uint256);

  function convertTokensToUsde30(
    address token,
    uint256 amountTokens,
    bool isUseMaxPrice
  ) external view returns (uint256);
}
