// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IUniswapRouter {
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);
}
