// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { LinkedList } from "../libraries/LinkedList.sol";

contract PoolConfig is OwnableUpgradeable {
  using LinkedList for LinkedList.List;

  error PoolConfig_BadNewFundingInterval();
  error PoolConfig_BadNewborrowingRateFactor();
  error PoolConfig_BadNewLiquidationFeeUsd();
  error PoolConfig_BadNewMaxLeverage();
  error PoolConfig_BadNewMintBurnFeeBps();
  error PoolConfig_BadNewPositionFeeBps();
  error PoolConfig_BadNewstableBorrowingRateFactor();
  error PoolConfig_BadNewStableTaxBps();
  error PoolConfig_BadNewStableSwapFeeBps();
  error PoolConfig_BadNewSwapFeeBps();
  error PoolConfig_BadNewTaxBps();
  error PoolConfig_ConfigContainsNotAcceptToken();
  error PoolConfig_TokensConfigsLengthMisMatch();

  // ---------
  // Constants
  // ---------
  uint256 internal constant MAX_FEE_BPS = 500;
  uint256 internal constant MIN_FUNDING_INTERVAL = 1 hours;
  // Max funding rate factor at 1% (10000 / 1000000 * 100 = 1%)
  uint256 internal constant MAX_FUNDING_RATE_FACTOR = 10000;
  uint256 internal constant MAX_LIQUIDATION_FEE_USD = 100 * 10**30;
  uint256 internal constant MIN_LEVERAGE = 10000;

  // --------
  // Treasury
  // --------
  address public treasury;

  // --------------------
  // Token Configurations
  // --------------------
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
  LinkedList.List public allowTokens;
  mapping(address => TokenConfig) public tokenMetas;
  uint256 public totalTokenWeight;

  // --------------------------
  // Liquidation configurations
  // --------------------------
  /// @notice liquidation fee in USD with 1e30 precision
  uint256 public liquidationFeeUsd;
  bool public isAllowAllLiquidators;
  mapping(address => bool) public allowLiquidators;

  // -----------------------
  // Leverage configurations
  // -----------------------
  uint64 public maxLeverage;

  // ---------------------------
  // Funding rate configurations
  // ---------------------------
  uint64 public fundingInterval;
  uint64 public stableBorrowingRateFactor;
  uint64 public borrowingRateFactor;

  // ----------------------
  // Fee bps configurations
  // ----------------------
  uint64 public mintBurnFeeBps;
  uint64 public taxBps;
  uint64 public stableTaxBps;
  uint64 public swapFeeBps;
  uint64 public stableSwapFeeBps;
  uint64 public positionFeeBps;

  // -----
  // Misc.
  // -----
  uint64 public minProfitDuration;
  bool public isDynamicFeeEnable;
  bool public isSwapEnable;
  bool public isLeverageEnable;

  address public router;

  event DeleteTokenConfig(address token);
  event SetAllowLiquidator(address liquidator, bool allow);
  event SetIsAllowAllLiquidators(
    bool prevIsAllowAllLiquidators,
    bool isAllowAllLiquidators
  );
  event SetIsDynamicFeeEnable(
    bool prevIsDynamicFeeEnable,
    bool newIsDynamicFeeEnable
  );
  event SetIsLeverageEnable(
    bool prevIsLeverageEnable,
    bool newIsLeverageEnable
  );
  event SetIsSwapEnable(bool prevIsSwapEnable, bool newIsSwapEnable);
  event SetMaxLeverage(uint256 prevMaxLeverage, uint256 newMaxLeverage);
  event SetMinProfitDuration(
    uint64 prevMinProfitDuration,
    uint64 newMinProfitDuration
  );
  event SetMintBurnFeeBps(uint256 prevFeeBps, uint256 newFeeBps);
  event SetFundingRate(
    uint64 prevFundingInterval,
    uint64 newFundingInterval,
    uint64 prevborrowingRateFactor,
    uint64 newborrowingRateFactor,
    uint64 prevstableBorrowingRateFactor,
    uint64 newstableBorrowingRateFactor
  );
  event SetLiquidationFeeUsd(
    uint256 prevLiquidationFeeUsd,
    uint256 newLiquidationFeeUsd
  );
  event SetPositionFeeBps(
    uint256 prevPositionFeeBps,
    uint256 newPositionFeeBps
  );
  event SetRouter(address prevRouter, address newRouter);
  event SetStableSwapFeeBps(
    uint256 prevStableSwapFeeBps,
    uint256 newStableSwapFeeBps
  );
  event SetStableTaxBps(uint256 prevStableTaxBps, uint256 newStableTaxBps);
  event SetSwapFeeBps(uint256 prevSwapFeeBps, uint256 newSwapFeeBps);
  event SetTaxBps(uint256 prevTaxBps, uint256 newTaxBps);
  event SetTokenConfig(
    address token,
    TokenConfig prevConfig,
    TokenConfig newConfig
  );
  event SetTreasury(address prevTreasury, address newTreasury);

  function initialize(
    address _treasury,
    uint64 _fundingInterval,
    uint64 _mintBurnFeeBps,
    uint64 _taxBps,
    uint64 _stableBorrowingRateFactor,
    uint64 _borrowingRateFactor,
    uint256 _liquidationFeeUsd
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    allowTokens.init();

    treasury = _treasury;

    fundingInterval = _fundingInterval;
    mintBurnFeeBps = _mintBurnFeeBps;
    taxBps = _taxBps;
    stableBorrowingRateFactor = _stableBorrowingRateFactor;
    borrowingRateFactor = _borrowingRateFactor;
    maxLeverage = 88 * 10000; // Max leverage at 88x

    // toggle
    isDynamicFeeEnable = false;
    isSwapEnable = true;
    isLeverageEnable = true;

    // Fee
    liquidationFeeUsd = _liquidationFeeUsd;
    stableSwapFeeBps = 4; // 0.04%
    swapFeeBps = 30; // 0.3%
    positionFeeBps = 10; // 0.1%
  }

  // ---------------
  // Admin functions
  // ---------------

  function setAllowLiquidators(address[] calldata liquidators, bool allow)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < liquidators.length; i++) {
      allowLiquidators[liquidators[i]] = allow;
      emit SetAllowLiquidator(liquidators[i], allow);
    }
  }

  function setFundingRate(
    uint64 newFundingInterval,
    uint64 newborrowingRateFactor,
    uint64 newstableBorrowingRateFactor
  ) external onlyOwner {
    if (newFundingInterval < MIN_FUNDING_INTERVAL)
      revert PoolConfig_BadNewFundingInterval();
    if (newborrowingRateFactor > MAX_FUNDING_RATE_FACTOR)
      revert PoolConfig_BadNewborrowingRateFactor();
    if (newstableBorrowingRateFactor > MAX_FUNDING_RATE_FACTOR)
      revert PoolConfig_BadNewstableBorrowingRateFactor();

    emit SetFundingRate(
      fundingInterval,
      newFundingInterval,
      borrowingRateFactor,
      newborrowingRateFactor,
      stableBorrowingRateFactor,
      newstableBorrowingRateFactor
    );
    fundingInterval = newFundingInterval;
    borrowingRateFactor = newborrowingRateFactor;
    stableBorrowingRateFactor = newstableBorrowingRateFactor;
  }

  function setIsAllowAllLiquidators(bool _isAllowAllLiquidators)
    external
    onlyOwner
  {
    emit SetIsAllowAllLiquidators(
      isAllowAllLiquidators,
      _isAllowAllLiquidators
    );
    isAllowAllLiquidators = _isAllowAllLiquidators;
  }

  function setIsDynamicFeeEnable(bool newIsDynamicFeeEnable)
    external
    onlyOwner
  {
    emit SetIsDynamicFeeEnable(isDynamicFeeEnable, newIsDynamicFeeEnable);
    isDynamicFeeEnable = newIsDynamicFeeEnable;
  }

  function setIsLeverageEnable(bool newIsLeverageEnable) external onlyOwner {
    emit SetIsLeverageEnable(isLeverageEnable, newIsLeverageEnable);
    isLeverageEnable = newIsLeverageEnable;
  }

  function setIsSwapEnable(bool newIsSwapEnable) external onlyOwner {
    emit SetIsSwapEnable(isSwapEnable, newIsSwapEnable);
    isSwapEnable = newIsSwapEnable;
  }

  function setLiquidationFeeUsd(uint256 newLiquidationFeeUsd)
    external
    onlyOwner
  {
    if (newLiquidationFeeUsd > MAX_LIQUIDATION_FEE_USD)
      revert PoolConfig_BadNewLiquidationFeeUsd();

    emit SetLiquidationFeeUsd(liquidationFeeUsd, newLiquidationFeeUsd);
    liquidationFeeUsd = newLiquidationFeeUsd;
  }

  function setMaxLeverage(uint64 newMaxLeverage) external onlyOwner {
    if (newMaxLeverage <= MIN_LEVERAGE) revert PoolConfig_BadNewMaxLeverage();

    emit SetMaxLeverage(maxLeverage, newMaxLeverage);
    maxLeverage = newMaxLeverage;
  }

  function setMinProfitDuration(uint64 newMinProfitDuration)
    external
    onlyOwner
  {
    emit SetMinProfitDuration(minProfitDuration, newMinProfitDuration);
    minProfitDuration = newMinProfitDuration;
  }

  function setMintBurnFeeBps(uint64 newMintBurnFeeBps) external onlyOwner {
    if (newMintBurnFeeBps > MAX_FEE_BPS)
      revert PoolConfig_BadNewMintBurnFeeBps();

    emit SetMintBurnFeeBps(mintBurnFeeBps, newMintBurnFeeBps);
    mintBurnFeeBps = newMintBurnFeeBps;
  }

  function setPositionFeeBps(uint64 newPositionFeeBps) external onlyOwner {
    if (newPositionFeeBps > MAX_FEE_BPS)
      revert PoolConfig_BadNewPositionFeeBps();

    emit SetPositionFeeBps(positionFeeBps, newPositionFeeBps);
    positionFeeBps = newPositionFeeBps;
  }

  function setRouter(address newRouter) external onlyOwner {
    emit SetRouter(router, newRouter);
    router = newRouter;
  }

  function setSwapFeeBps(uint64 newSwapFeeBps, uint64 newStableSwapFeeBps)
    external
    onlyOwner
  {
    if (newSwapFeeBps > MAX_FEE_BPS) revert PoolConfig_BadNewSwapFeeBps();
    if (newStableSwapFeeBps > MAX_FEE_BPS)
      revert PoolConfig_BadNewStableSwapFeeBps();

    emit SetSwapFeeBps(swapFeeBps, newSwapFeeBps);
    emit SetStableSwapFeeBps(stableSwapFeeBps, newStableSwapFeeBps);

    swapFeeBps = newSwapFeeBps;
    stableSwapFeeBps = newStableSwapFeeBps;
  }

  function setTaxBps(uint64 newTaxBps, uint64 newStableTaxBps)
    external
    onlyOwner
  {
    if (newTaxBps > MAX_FEE_BPS) revert PoolConfig_BadNewTaxBps();
    if (newStableTaxBps > MAX_FEE_BPS) revert PoolConfig_BadNewStableTaxBps();

    emit SetTaxBps(taxBps, newTaxBps);
    emit SetStableTaxBps(stableTaxBps, newStableTaxBps);

    taxBps = newTaxBps;
    stableTaxBps = newStableTaxBps;
  }

  function setTokenConfigs(
    address[] calldata tokens,
    TokenConfig[] calldata configs
  ) external onlyOwner {
    if (tokens.length != configs.length)
      revert PoolConfig_TokensConfigsLengthMisMatch();

    for (uint256 i = 0; i < tokens.length; ) {
      // Enforce that accept must be true
      if (!configs[i].accept) revert PoolConfig_ConfigContainsNotAcceptToken();

      // If tokenMetas.accept previously false, then it is a new token to be added.
      if (!tokenMetas[tokens[i]].accept) allowTokens.add(tokens[i]);

      emit SetTokenConfig(tokens[i], tokenMetas[tokens[i]], configs[i]);

      totalTokenWeight =
        (totalTokenWeight - tokenMetas[tokens[i]].weight) +
        configs[i].weight;
      tokenMetas[tokens[i]] = configs[i];

      unchecked {
        ++i;
      }
    }
  }

  function setTreasury(address newTreasury) external onlyOwner {
    emit SetTreasury(treasury, newTreasury);
    treasury = newTreasury;
  }

  function deleteTokenConfig(address token) external onlyOwner {
    // Update totalTokenWeight
    totalTokenWeight -= tokenMetas[token].weight;

    // Delete configs from storage
    allowTokens.remove(token, allowTokens.getPreviousOf(token));
    delete tokenMetas[token];

    emit DeleteTokenConfig(token);
  }

  // ----------------
  // Getter functions
  // ----------------

  function isAcceptToken(address token) external view returns (bool) {
    return tokenMetas[token].accept;
  }

  function isAllowedLiquidators(address liquidator)
    external
    view
    returns (bool)
  {
    return
      isAllowAllLiquidators
        ? isAllowAllLiquidators
        : allowLiquidators[liquidator];
  }

  function isStableToken(address token) external view returns (bool) {
    return tokenMetas[token].isStable;
  }

  function isShortableToken(address token) external view returns (bool) {
    return tokenMetas[token].isShortable;
  }

  function getAllowTokensLength() external view returns (uint256) {
    return allowTokens.size;
  }

  function getNextAllowTokenOf(address token) external view returns (address) {
    return allowTokens.getNextOf(token);
  }

  function getTokenBufferLiquidityOf(address token)
    external
    view
    returns (uint256)
  {
    return tokenMetas[token].bufferLiquidity;
  }

  function getTokenDecimalsOf(address token) external view returns (uint8) {
    return tokenMetas[token].decimals;
  }

  function getTokenMinProfitBpsOf(address token)
    external
    view
    returns (uint256)
  {
    return tokenMetas[token].minProfitBps;
  }

  function getTokenWeightOf(address token) external view returns (uint256) {
    return tokenMetas[token].weight;
  }

  function getTokenUsdDebtCeilingOf(address token)
    external
    view
    returns (uint256)
  {
    return tokenMetas[token].usdDebtCeiling;
  }

  function getTokenShortCeilingOf(address token)
    external
    view
    returns (uint256)
  {
    return tokenMetas[token].shortCeiling;
  }

  function shouldUpdateBorrowingRate(
    address, /* collateralToken */
    address /* indexToken */
  ) external pure returns (bool) {
    return true;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
