// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface LiquidityFacetInterface {
  function addLiquidity(
    address account,
    address token,
    address receiver
  ) external returns (uint256);
}
