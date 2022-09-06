// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { BaseMintableToken } from "./base/BaseMintableToken.sol";

contract PLP is BaseMintableToken {
  constructor() BaseMintableToken("P88 Liquidity Provider", "PLP", 18) {}
}
