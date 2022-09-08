// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface FundingRateFacetInterface {
  function updateFundingRate(address collateralToken, address indexToken)
    external;
}
