// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { LibPoolConfigV1 } from "../libraries/LibPoolConfigV1.sol";
import { LinkedList } from "../../../libraries/LinkedList.sol";

contract PoolConfigInitializer {
  using LinkedList for LinkedList.List;

  function initialize(
    address treasury,
    uint64 fundingInterval,
    uint64 mintBurnFeeBps,
    uint64 taxBps,
    uint64 stableFundingRateFactor,
    uint64 fundingRateFactor,
    uint64 liquidityCoolDownDuration,
    uint256 liquidationFeeUsd
  ) external {
    LibPoolConfigV1.PoolConfigV1DiamondStorage
      storage poolConfigDs = LibPoolConfigV1.poolConfigV1DiamondStorage();

    poolConfigDs.allowTokens.init();

    poolConfigDs.treasury = treasury;

    poolConfigDs.fundingInterval = fundingInterval;
    poolConfigDs.mintBurnFeeBps = mintBurnFeeBps;
    poolConfigDs.taxBps = taxBps;
    poolConfigDs.stableFundingRateFactor = stableFundingRateFactor;
    poolConfigDs.fundingRateFactor = fundingRateFactor;
    poolConfigDs.liquidityCoolDownDuration = liquidityCoolDownDuration;
    poolConfigDs.liquidationFeeUsd = liquidationFeeUsd;

    poolConfigDs.maxLeverage = 88 * 10000;

    poolConfigDs.isDynamicFeeEnable = false;
    poolConfigDs.isSwapEnable = true;
    poolConfigDs.isLeverageEnable = true;

    poolConfigDs.liquidationFeeUsd = liquidationFeeUsd;
    poolConfigDs.stableSwapFeeBps = 4;
    poolConfigDs.swapFeeBps = 30;
    poolConfigDs.positionFeeBps = 10;
  }
}
