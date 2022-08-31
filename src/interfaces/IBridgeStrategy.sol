// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IBridgeStrategy {
  function execute(
    address caller,
    uint256 destinationChainId,
    address destinationAddress,
    uint256 amount,
    bytes memory payload
  ) external payable;
}
