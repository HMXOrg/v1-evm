// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { LinkedList } from "../../../libraries/LinkedList.sol";

library LibPoolConfigV1 {
  using LinkedList for LinkedList.List;

  // -------------
  //    Constants
  // -------------
  // keccak256("com.perp88.poolconfigv1.diamond.storage")
  bytes32 internal constant POOL_CONFIG_V1_STORAGE_POSITION =
    0x98a7856657bef7cc5eba088ed024ebd08d8fb7eed7a3fcb52b2c50657b3073e6;

  // -------------
  //    Storage
  // -------------
  struct TokenConfig {
    bool accept;
    bool isStable;
    bool isShortable;
    uint8 decimals;
    uint64 weight;
    uint64 minProfitBps;
    uint256 usdDebtCeiling;
    uint256 shortCeiling;
    uint256 bufferLiquidity;
  }

  struct PoolConfigV1DiamondStorage {
    // --------
    // Treasury
    // --------
    address treasury;
    // --------------------
    // Token Configurations
    // --------------------
    LinkedList.List allowTokens;
    mapping(address => TokenConfig) tokenMetas;
    uint256 totalTokenWeight;
    // --------------------------
    // Liquidation configurations
    // --------------------------
    /// @notice liquidation fee in USD with 1e30 precision
    uint256 liquidationFeeUsd;
    bool isAllowAllLiquidators;
    mapping(address => bool) allowLiquidators;
    // -----------------------
    // Leverage configurations
    // -----------------------
    uint64 maxLeverage;
    // ---------------------------
    // Funding rate configurations
    // ---------------------------
    uint64 fundingInterval;
    uint64 stableFundingRateFactor;
    uint64 fundingRateFactor;
    // ----------------------
    // Fee bps configurations
    // ----------------------
    uint64 mintBurnFeeBps;
    uint64 taxBps;
    uint64 stableTaxBps;
    uint64 swapFeeBps;
    uint64 stableSwapFeeBps;
    uint64 positionFeeBps;
    // -----
    // Misc.
    // -----
    uint64 minProfitDuration;
    uint64 liquidityCoolDownDuration;
    bool isDynamicFeeEnable;
    bool isSwapEnable;
    bool isLeverageEnable;
    address router;
  }

  function poolConfigV1DiamondStorage()
    internal
    pure
    returns (PoolConfigV1DiamondStorage storage poolConfigV1Ds)
  {
    assembly {
      poolConfigV1Ds.slot := POOL_CONFIG_V1_STORAGE_POSITION
    }
  }

  function fundingInterval() internal view returns (uint256) {
    return poolConfigV1DiamondStorage().fundingInterval;
  }

  function getAllowTokensLength() internal view returns (uint256) {
    return poolConfigV1DiamondStorage().allowTokens.size;
  }

  function getNextAllowTokenOf(address token) internal view returns (address) {
    return poolConfigV1DiamondStorage().allowTokens.getNextOf(token);
  }

  function getTokenBufferLiquidityOf(address token)
    internal
    view
    returns (uint256)
  {
    return poolConfigV1DiamondStorage().tokenMetas[token].bufferLiquidity;
  }

  function getTokenDecimalsOf(address token) internal view returns (uint8) {
    return poolConfigV1DiamondStorage().tokenMetas[token].decimals;
  }

  function getTokenMinProfitBpsOf(address token)
    internal
    view
    returns (uint256)
  {
    return poolConfigV1DiamondStorage().tokenMetas[token].minProfitBps;
  }

  function getTokenWeightOf(address token) internal view returns (uint256) {
    return poolConfigV1DiamondStorage().tokenMetas[token].weight;
  }

  function getTokenUsdDebtCeilingOf(address token)
    internal
    view
    returns (uint256)
  {
    return poolConfigV1DiamondStorage().tokenMetas[token].usdDebtCeiling;
  }

  function getTokenShortCeilingOf(address token)
    internal
    view
    returns (uint256)
  {
    return poolConfigV1DiamondStorage().tokenMetas[token].shortCeiling;
  }

  function isAcceptToken(address token) internal view returns (bool) {
    return poolConfigV1DiamondStorage().tokenMetas[token].accept;
  }

  function isAllowedLiquidators(address liquidator)
    internal
    view
    returns (bool)
  {
    // Load PoolConfigV1 diamond storage
    PoolConfigV1DiamondStorage
      storage poolConfigV1Ds = poolConfigV1DiamondStorage();

    return
      poolConfigV1Ds.isAllowAllLiquidators
        ? true
        : poolConfigV1Ds.allowLiquidators[liquidator];
  }

  function isDynamicFeeEnable() internal view returns (bool) {
    return poolConfigV1DiamondStorage().isDynamicFeeEnable;
  }

  function isLeverageEnable() internal view returns (bool) {
    return poolConfigV1DiamondStorage().isLeverageEnable;
  }

  function isStableToken(address token) internal view returns (bool) {
    return poolConfigV1DiamondStorage().tokenMetas[token].isStable;
  }

  function isShortableToken(address token) internal view returns (bool) {
    return poolConfigV1DiamondStorage().tokenMetas[token].isShortable;
  }

  function isSwapEnable() internal view returns (bool) {
    return poolConfigV1DiamondStorage().isSwapEnable;
  }

  function liquidationFeeUsd() internal view returns (uint256) {
    return poolConfigV1DiamondStorage().liquidationFeeUsd;
  }

  function liquidityCoolDownDuration() internal view returns (uint64) {
    return poolConfigV1DiamondStorage().liquidityCoolDownDuration;
  }

  function maxLeverage() internal view returns (uint64) {
    return poolConfigV1DiamondStorage().maxLeverage;
  }

  function treasury() internal view returns (address) {
    return poolConfigV1DiamondStorage().treasury;
  }
}
