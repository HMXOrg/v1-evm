// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface FlashLoanBorrowerInterface {
  function onFlashLoan(
    address caller,
    address[] calldata tokens,
    uint256[] calldata amounts,
    uint256[] calldata fees,
    bytes calldata data
  ) external;
}
