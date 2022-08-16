// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IPool } from "../../interfaces/IPool.sol";

contract MockPool is IPool {
  function addLiquidity(
    address token,
    uint256 amount,
    address receiver,
    uint256 minLiquidity
  ) public returns (uint256) {
    return 20;
  }
}
