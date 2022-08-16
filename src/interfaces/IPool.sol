// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IPool {
 function addLiquidity(
    address token,
    uint256 amount,
    address receiver,
    uint256 minLiquidity
  ) external returns (uint256);
}