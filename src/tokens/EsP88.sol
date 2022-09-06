// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { BaseMintableToken } from "./base/BaseMintableToken.sol";

contract EsP88 is BaseMintableToken {
  constructor()
    BaseMintableToken("Escrowed P88", "esP88", 18, type(uint256).max)
  {}
}
