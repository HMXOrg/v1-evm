// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { BaseMintableToken } from "./base/BaseMintableToken.sol";

contract EsP88 is BaseMintableToken {
  constructor() BaseMintableToken("Escrowed P88", "esP88", 18) {}
}
