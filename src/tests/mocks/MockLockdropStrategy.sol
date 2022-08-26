// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ILockdropStrategy } from "../../lockdrop/interfaces/ILockdropStrategy.sol";

contract MockLockdropStrategy is ILockdropStrategy {
  function execute(uint256 tokenAmount, address tokenAddress)
    external
    returns (uint256)
  {
    return tokenAmount * 2;
  }
}
