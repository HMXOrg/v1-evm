// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { LibReentrancyGuard } from "../libraries/LibReentrancyGuard.sol";
import { LibPoolV1 } from "../libraries/LibPoolV1.sol";

import { PerpTradeFacetInterface } from "../interfaces/PerpTradeFacetInterface.sol";
import { GetterFacetInterface } from "../interfaces/GetterFacetInterface.sol";
import { FundingRateFacetInterface } from "../interfaces/FundingRateFacetInterface.sol";

contract PerpTradeFacet is PerpTradeFacetInterface {
  error PerpTradeFacet_BadToken();
  error PerpTradeFacet_BadPositionSize();
  error PerpTradeFacet_CollateralNotCoverFee();
  error PerpTradeFacet_CollateralTokenIsStable();
  error PerpTradeFacet_CollateralTokenNotStable();
  error PerpTradeFacet_FeeExceedCollateral();
  error PerpTradeFacet_IndexTokenIsStable();
  error PerpTradeFacet_IndexTokenNotShortable();
  error PerpTradeFacet_LeverageDisabled();
  error PerpTradeFacet_LiquidationFeeExceedCollateral();
  error PerpTradeFacet_LossesExceedCollateral();
  error PerpTradeFacet_MaxLeverageExceed();
  error PerpTradeFacet_SizeSmallerThanCollateral();
  error PerpTradeFacet_TokenMisMatch();

  uint256 internal constant BPS = 10000;

  event CollectMarginFee(address token, uint256 feeUsd, uint256 feeTokens);
  event IncreasePosition(
    bytes32 posId,
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 collateralDeltaUsd,
    uint256 sizeDelta,
    bool isLong,
    uint256 price,
    uint256 feeUsd
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

  function checkLiquidation(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong,
    bool isRevertOnError
  ) public view returns (LiquidationState, uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    LibPoolV1.Position memory position = ds.positions[
      LibPoolV1.getPositionId(account, collateralToken, indexToken, isLong)
    ];

    (bool isProfit, uint256 delta) = GetterFacetInterface(address(this))
      .getDelta(
        indexToken,
        position.size,
        position.averagePrice,
        isLong,
        position.lastIncreasedTime
      );
    uint256 marginFee = GetterFacetInterface(address(this)).getFundingFee(
      account,
      collateralToken,
      indexToken,
      isLong,
      position.size,
      position.entryFundingRate
    );
    marginFee += GetterFacetInterface(address(this)).getPositionFee(
      account,
      collateralToken,
      indexToken,
      isLong,
      position.size
    );

    if (!isProfit && position.collateral < delta) {
      if (isRevertOnError) revert PerpTradeFacet_LossesExceedCollateral();
      return (LiquidationState.LIQUIDATE, marginFee);
    }

    uint256 remainingCollateral = position.collateral;
    if (!isProfit) {
      remainingCollateral -= delta;
    }

    if (remainingCollateral < marginFee) {
      if (isRevertOnError) revert PerpTradeFacet_FeeExceedCollateral();
      // Cap the fee to the remainingCollateral.
      return (LiquidationState.LIQUIDATE, remainingCollateral);
    }

    if (remainingCollateral < marginFee + ds.config.liquidationFeeUsd()) {
      if (isRevertOnError)
        revert PerpTradeFacet_LiquidationFeeExceedCollateral();
      // Cap the fee to the margin fee
      return (LiquidationState.LIQUIDATE, marginFee);
    }

    if (remainingCollateral * ds.config.maxLeverage() < position.size * BPS) {
      if (isRevertOnError) revert PerpTradeFacet_MaxLeverageExceed();
      return (LiquidationState.SOFT_LIQUIDATE, marginFee);
    }

    return (LiquidationState.HEALTHY, marginFee);
  }

  function _checkPosition(uint256 size, uint256 collateral) internal pure {
    if (size == 0) {
      if (collateral != 0) revert PerpTradeFacet_SizeSmallerThanCollateral();
      return;
    }
    if (size < collateral) revert PerpTradeFacet_SizeSmallerThanCollateral();
  }

  function _collectMarginFee(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong,
    uint256 sizeDelta,
    uint256 size,
    uint256 entryFundingRate
  ) internal returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    uint256 feeUsd = GetterFacetInterface(address(this)).getPositionFee(
      account,
      collateralToken,
      indexToken,
      isLong,
      sizeDelta
    );

    uint256 fundingFeeUsd = GetterFacetInterface(address(this)).getFundingFee(
      account,
      collateralToken,
      indexToken,
      isLong,
      size,
      entryFundingRate
    );

    feeUsd += fundingFeeUsd;

    uint256 feeTokens = LibPoolV1.convertUsde30ToTokens(
      collateralToken,
      feeUsd,
      true
    );
    ds.feeReserveOf[collateralToken] += feeTokens;

    emit CollectMarginFee(collateralToken, feeUsd, feeTokens);

    return feeUsd;
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
  /// @param isLong The exposure that the position is in. Either Long or Short.
  function increasePosition(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 sizeDelta,
    bool isLong
  ) external {
    LibReentrancyGuard.lock();
    LibPoolV1.allowed(primaryAccount);

    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    if (!ds.config.isLeverageEnable()) revert PerpTradeFacet_LeverageDisabled();
    _checkTokenInputs(collateralToken, indexToken, isLong);
    // TODO: Add validate increase position

    FundingRateFacetInterface(address(this)).updateFundingRate(
      collateralToken,
      indexToken
    );

    IncreasePositionLocalVars memory vars;

    vars.subAccount = LibPoolV1.getSubAccount(primaryAccount, subAccountId);

    vars.posId = LibPoolV1.getPositionId(
      vars.subAccount,
      collateralToken,
      indexToken,
      isLong
    );
    LibPoolV1.Position storage position = ds.positions[vars.posId];

    vars.price = isLong
      ? ds.oracle.getMaxPrice(indexToken)
      : ds.oracle.getMinPrice(indexToken);

    if (position.size == 0) {
      // If position size = 0, then it is a new position.
      // So make average price to equal to price.
      // And assign the primary account
      position.averagePrice = vars.price;
      position.primaryAccount = primaryAccount;
    }

    if (position.size > 0 && sizeDelta > 0) {
      // If position size > 0, then position is existed.
      // Need to calculate the next average price.
      position.averagePrice = GetterFacetInterface(address(this))
        .getPositionNextAveragePrice(
          indexToken,
          position.size,
          position.averagePrice,
          isLong,
          vars.price,
          sizeDelta,
          position.lastIncreasedTime
        );
    }

    vars.feeUsd = _collectMarginFee(
      vars.subAccount,
      collateralToken,
      indexToken,
      isLong,
      sizeDelta,
      position.size,
      position.entryFundingRate
    );
    vars.collateralDelta = LibPoolV1.pullTokens(collateralToken);
    vars.collateralDeltaUsd = LibPoolV1.convertTokensToUsde30(
      collateralToken,
      vars.collateralDelta,
      false
    );

    position.collateral += vars.collateralDeltaUsd;
    if (position.collateral < vars.feeUsd)
      revert PerpTradeFacet_CollateralNotCoverFee();

    position.collateral -= vars.feeUsd;
    position.entryFundingRate = GetterFacetInterface(address(this))
      .getEntryFundingRate(collateralToken, indexToken, isLong);
    position.size += sizeDelta;
    position.lastIncreasedTime = block.timestamp;

    if (position.size == 0) revert PerpTradeFacet_BadPositionSize();
    _checkPosition(position.size, position.collateral);
    checkLiquidation(
      vars.subAccount,
      collateralToken,
      indexToken,
      isLong,
      true
    );

    // Lock tokens in reserved to pay for profits on this position.
    uint256 reserveDelta = LibPoolV1.convertUsde30ToTokens(
      collateralToken,
      sizeDelta,
      false
    );
    position.reserveAmount += reserveDelta;
    LibPoolV1.increaseReserved(collateralToken, reserveDelta);

    if (isLong) {
      // guaranteedUsd stores the sum of (position.size - position.collateral) for all positions
      // if a fee is charged on the collateral then guaranteedUsd should be increased by that fee amount
      // since (position.size - position.collateral) would have increased by `fee`
      LibPoolV1.increaseGuaranteedUsd(collateralToken, sizeDelta + vars.feeUsd);
      LibPoolV1.decreaseGuaranteedUsd(collateralToken, vars.collateralDeltaUsd);

      // treat the deposited collateral as part of the pool
      LibPoolV1.increasePoolLiquidity(collateralToken, vars.collateralDelta);

      // fees need to be deducted from the pool since fees are deducted from position.collateral
      // and collateral is treated as part of the pool
      LibPoolV1.decreasePoolLiquidity(
        collateralToken,
        LibPoolV1.convertUsde30ToTokens(collateralToken, vars.feeUsd, true)
      );
    } else {
      if (ds.shortSizeOf[indexToken] == 0)
        ds.shortAveragePriceOf[indexToken] = vars.price;
      else
        ds.shortAveragePriceOf[indexToken] = GetterFacetInterface(address(this))
          .getNextShortAveragePrice(indexToken, vars.price, sizeDelta);

      LibPoolV1.increaseShortSize(indexToken, sizeDelta);
    }

    emit IncreasePosition(
      vars.posId,
      primaryAccount,
      subAccountId,
      collateralToken,
      indexToken,
      vars.collateralDeltaUsd,
      sizeDelta,
      isLong,
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

    LibReentrancyGuard.unlock();
  }

  function _checkTokenInputs(
    address collateralToken,
    address indexToken,
    bool isLong
  ) internal view {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    if (isLong) {
      if (collateralToken != indexToken) revert PerpTradeFacet_TokenMisMatch();
      if (!ds.config.isAcceptToken(collateralToken))
        revert PerpTradeFacet_BadToken();
      if (ds.config.isStableToken(collateralToken))
        revert PerpTradeFacet_CollateralTokenIsStable();
      return;
    }

    if (!ds.config.isAcceptToken(collateralToken))
      revert PerpTradeFacet_BadToken();
    if (!ds.config.isStableToken(collateralToken))
      revert PerpTradeFacet_CollateralTokenNotStable();
    if (ds.config.isStableToken(indexToken))
      revert PerpTradeFacet_IndexTokenIsStable();
    if (!ds.config.isShortableToken(indexToken))
      revert PerpTradeFacet_IndexTokenNotShortable();
  }
}
