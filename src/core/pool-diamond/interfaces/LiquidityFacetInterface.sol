// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface LiquidityFacetInterface {
  function addLiquidity(
    address account,
    address token,
    address receiver
  ) external returns (uint256);

  function removeLiquidity(
    address account,
    address tokenOut,
    address receiver
  ) external returns (uint256);

  function swap(
    address tokenIn,
    address tokenOut,
    uint256 minAmountOut,
    address receiver
  ) external returns (uint256);
}
