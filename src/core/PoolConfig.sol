// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { LinkedList } from "../libraries/LinkedList.sol";

contract PoolConfig is Ownable {
  using LinkedList for LinkedList.List;

  error PoolConfig_BadArguments();

  struct TokenConfig {
    bool accept;
    bool isStable;
    bool isShortable;
    uint8 decimals;
    uint64 weight;
    uint64 minProfitBps;
    uint256 usdDebtCeiling;
    uint256 shortCeiling;
  }
  LinkedList.List public allowTokens;
  mapping(address => TokenConfig) public tokenMetas;
  uint256 public totalTokenWeight;

  // ---------------------------
  // Funding rate configurations
  // ---------------------------
  uint64 public fundingInterval;
  uint64 public stableFundingRateFactor;
  uint64 public fundingRateFactor;

  // ------------------
  // Fee configurations
  // ------------------
  uint64 public mintBurnFeeBps;
  uint64 public taxBps;
  uint64 public stableTaxBps;
  uint64 public swapFeeBps;
  uint64 public stableSwapFeeBps;

  // -----
  // Misc.
  // -----
  uint64 public liquidityCoolDownDuration;
  bool public isDynamicFeeEnable;
  bool public isSwapEnable;

  event DeleteTokenConfig(address token);
  event SetIsDynamicFeeEnable(
    bool prevIsDynamicFeeEnable,
    bool newIsDynamicFeeEnable
  );
  event SetMintBurnFeeBps(uint256 prevFeeBps, uint256 newFeeBps);
  event SetFundingRate(
    uint64 prevFundingInterval,
    uint64 newFundingInterval,
    uint64 prevFundingRateFactor,
    uint64 newFundingRateFactor,
    uint64 prevStableFundingRateFactor,
    uint64 newStableFundingRateFactor
  );
  event SetLiquidityCoolDownDuration(
    uint256 prevCoolDownPeriod,
    uint256 newCoolDownPeriod
  );
  event SetTaxBps(uint256 prevTaxBps, uint256 newTaxBps);
  event SetTokenConfig(
    address token,
    TokenConfig prevConfig,
    TokenConfig newConfig
  );
  event SetIsSwapEnable(bool prevIsSwapEnable, bool newIsSwapEnable);

  constructor(
    uint64 _fundingInterval,
    uint64 _mintBurnFeeBps,
    uint64 _taxBps,
    uint64 _stableFundingRateFactor,
    uint64 _fundingRateFactor,
    uint64 _liquidityCoolDownDuration
  ) {
    allowTokens.init();

    fundingInterval = _fundingInterval;
    mintBurnFeeBps = _mintBurnFeeBps;
    taxBps = _taxBps;
    stableFundingRateFactor = _stableFundingRateFactor;
    fundingRateFactor = _fundingRateFactor;
    liquidityCoolDownDuration = _liquidityCoolDownDuration;

    // toggle
    isDynamicFeeEnable = false;
    isSwapEnable = true;

    // Fee
    stableSwapFeeBps = 4; // 0.04%
    swapFeeBps = 30; // 0.3%
  }

  function setIsDynamicFeeEnable(bool newIsDynamicFeeEnable)
    external
    onlyOwner
  {
    emit SetIsDynamicFeeEnable(isDynamicFeeEnable, newIsDynamicFeeEnable);
    isDynamicFeeEnable = newIsDynamicFeeEnable;
  }

  function setIsSwapEnable(bool newIsSwapEnable) external onlyOwner {
    emit SetIsSwapEnable(isSwapEnable, newIsSwapEnable);
    isSwapEnable = newIsSwapEnable;
  }

  function setFundingRate(
    uint64 newFundingInterval,
    uint64 newFundingRateFactor,
    uint64 newStableFundingRateFactor
  ) external onlyOwner {
    emit SetFundingRate(
      fundingInterval,
      newFundingInterval,
      fundingRateFactor,
      newFundingRateFactor,
      stableFundingRateFactor,
      newStableFundingRateFactor
    );
    fundingInterval = newFundingInterval;
    fundingRateFactor = newFundingRateFactor;
    stableFundingRateFactor = newStableFundingRateFactor;
  }

  function setLiquidityCoolDownDuration(uint64 newLiquidityCoolDownPeriod)
    external
    onlyOwner
  {
    emit SetLiquidityCoolDownDuration(
      liquidityCoolDownDuration,
      newLiquidityCoolDownPeriod
    );
    liquidityCoolDownDuration = newLiquidityCoolDownPeriod;
  }

  function setMintBurnFeeBps(uint64 newMintBurnFeeBps) external onlyOwner {
    emit SetMintBurnFeeBps(mintBurnFeeBps, newMintBurnFeeBps);
    mintBurnFeeBps = newMintBurnFeeBps;
  }

  function setTaxBps(uint64 newTaxBps) external onlyOwner {
    emit SetTaxBps(taxBps, newTaxBps);
    taxBps = newTaxBps;
  }

  function setTokenConfigs(
    address[] calldata tokens,
    TokenConfig[] calldata configs
  ) external onlyOwner {
    if (tokens.length != configs.length) revert PoolConfig_BadArguments();

    for (uint256 i = 0; i < tokens.length; ) {
      // Enforce that accept must be true
      if (!configs[i].accept) revert PoolConfig_BadArguments();

      // If tokenMetas.accept previously false, then it is a new token to be added.
      if (!tokenMetas[tokens[i]].accept) allowTokens.add(tokens[i]);

      emit SetTokenConfig(tokens[i], tokenMetas[tokens[i]], configs[i]);

      totalTokenWeight -= tokenMetas[tokens[i]].weight;
      totalTokenWeight += configs[i].weight;
      tokenMetas[tokens[i]] = configs[i];

      unchecked {
        ++i;
      }
    }
  }

  function deleteTokenConfig(address token) external onlyOwner {
    allowTokens.remove(token, allowTokens.getPreviousOf(token));
    delete tokenMetas[token];

    emit DeleteTokenConfig(token);
  }

  function isAcceptToken(address token) external view returns (bool) {
    return tokenMetas[token].accept;
  }

  function isStableToken(address token) external view returns (bool) {
    return tokenMetas[token].isStable;
  }

  function getAllowTokensLength() external view returns (uint256) {
    return allowTokens.size;
  }

  function getNextAllowTokenOf(address token) external view returns (address) {
    return allowTokens.getNextOf(token);
  }

  function tokenDecimals(address token) external view returns (uint8) {
    return tokenMetas[token].decimals;
  }

  function tokenWeight(address token) external view returns (uint256) {
    return tokenMetas[token].weight;
  }

  function tokenUsdDebtCeiling(address token) external view returns (uint256) {
    return tokenMetas[token].usdDebtCeiling;
  }

  function tokenShortCeiling(address token) external view returns (uint256) {
    return tokenMetas[token].shortCeiling;
  }
}
