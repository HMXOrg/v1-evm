// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibPoolV1 } from "../libraries/LibPoolV1.sol";
import { LibPoolConfigV1 } from "../libraries/LibPoolConfigV1.sol";

import { FundingRateFacetInterface } from "../interfaces/FundingRateFacetInterface.sol";
import { GetterFacetInterface } from "../interfaces/GetterFacetInterface.sol";

contract FundingRateFacet is FundingRateFacetInterface {
  event UpdateFundingRate(address token, uint256 sumFundingRate);

  function updateFundingRate(
    address collateralToken,
    address /* indexToken */
  ) external {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    uint256 fundingInterval = LibPoolConfigV1.fundingInterval();

    if (poolV1ds.lastFundingTimeOf[collateralToken] == 0) {
      poolV1ds.lastFundingTimeOf[collateralToken] =
        (block.timestamp / fundingInterval) *
        fundingInterval;
      return;
    }

    // If block.timestamp is not passed the next funding interval, do nothing.
    if (
      poolV1ds.lastFundingTimeOf[collateralToken] + fundingInterval >
      block.timestamp
    ) {
      return;
    }

    uint256 fundingRate = GetterFacetInterface(address(this))
      .getNextFundingRate(collateralToken);
    unchecked {
      poolV1ds.sumFundingRateOf[collateralToken] += fundingRate;
      poolV1ds.lastFundingTimeOf[collateralToken] =
        (block.timestamp / fundingInterval) *
        fundingInterval;
    }

    emit UpdateFundingRate(
      collateralToken,
      poolV1ds.sumFundingRateOf[collateralToken]
    );
  }
}
