// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface FundingRateFacetInterface {
  function updateFundingRate(
    address collateralToken,
    address indexToken
  ) external;
}
