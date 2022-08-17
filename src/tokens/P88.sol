// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { BaseMintableToken } from "./base/BaseMintableToken.sol";

contract P88 is BaseMintableToken {
  constructor() BaseMintableToken("Perp88", "P88", 18) {}
}
