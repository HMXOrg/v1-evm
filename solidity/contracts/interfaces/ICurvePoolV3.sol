// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface ICurvePoolV3 {
  function balances(uint256 tokenIndex) external view returns (uint256);
}
