// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibPoolV1 } from "../libraries/LibPoolV1.sol";
import { LibPoolConfigV1 } from "../libraries/LibPoolConfigV1.sol";

import { FundingRateFacetInterface } from "../interfaces/FundingRateFacetInterface.sol";
import { GetterFacetInterface } from "../interfaces/GetterFacetInterface.sol";
import { console } from "src/tests/utils/console.sol";

contract FundingRateFacet is FundingRateFacetInterface {
  event UpdateBorrowingRate(address token, uint256 sumBorrowingRate);
  event UpdateFundingRate(
    address token,
    int256 sumRateLong,
    int256 sumRateShort
  );

  function updateFundingRate(address collateralToken, address indexToken)
    external
  {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    uint256 fundingInterval = LibPoolConfigV1.fundingInterval();

    if (poolV1ds.lastFundingTimeOf[collateralToken] == 0) {
      poolV1ds.lastFundingTimeOf[collateralToken] =
        (block.timestamp / fundingInterval) *
        fundingInterval;
    }

    if (poolV1ds.lastFundingTimeOf[indexToken] == 0) {
      poolV1ds.lastFundingTimeOf[indexToken] =
        (block.timestamp / fundingInterval) *
        fundingInterval;
    }

    // If block.timestamp is not passed the next funding interval, do nothing.
    console.log(
      "poolV1ds.lastFundingTimeOf[collateralToken]",
      poolV1ds.lastFundingTimeOf[collateralToken]
    );
    console.log(
      "poolV1ds.lastFundingTimeOf[indexToken]",
      poolV1ds.lastFundingTimeOf[indexToken]
    );
    console.log("fundingInterval", fundingInterval);
    console.log("block.timestamp", block.timestamp);
    if (
      poolV1ds.lastFundingTimeOf[collateralToken] + fundingInterval <=
      block.timestamp
    ) {
      uint256 borrowingRate = GetterFacetInterface(address(this))
        .getNextBorrowingRate(collateralToken);
      unchecked {
        poolV1ds.sumBorrowingRateOf[collateralToken] += borrowingRate;
      }

      console.log("borrowingRate", borrowingRate);

      emit UpdateBorrowingRate(
        collateralToken,
        poolV1ds.sumBorrowingRateOf[collateralToken]
      );
    }

    if (
      poolV1ds.lastFundingTimeOf[indexToken] + fundingInterval <=
      block.timestamp
    ) {
      (int256 fundingRateLong, int256 fundingRateShort) = GetterFacetInterface(
        address(this)
      ).getNextFundingRate(indexToken);
      unchecked {
        poolV1ds.accumFundingRateLong[indexToken] += fundingRateLong;
        poolV1ds.accumFundingRateShort[indexToken] += fundingRateShort;
        poolV1ds.lastFundingTimeOf[indexToken] =
          (block.timestamp / fundingInterval) *
          fundingInterval;
      }
      console.log("fundingRateLong");
      console.logInt(fundingRateLong);
      console.log("fundingRateShort");
      console.logInt(fundingRateShort);

      emit UpdateFundingRate(
        indexToken,
        poolV1ds.accumFundingRateLong[indexToken],
        poolV1ds.accumFundingRateShort[indexToken]
      );
    }
  }
}
