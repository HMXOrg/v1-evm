// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ILockdropStrategy {
  function execute(uint256 tokenAmount, address tokenAddress)
    external
    returns (uint256);
}
