// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./MintableToken.sol";

contract P88 is MintableToken {
  constructor() ERC20("P88", "P88") {
  }
}