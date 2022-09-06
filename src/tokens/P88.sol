// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { BaseBridgeableToken } from "./base/BaseBridgeableToken.sol";

contract P88 is BaseBridgeableToken {
  constructor(bool isBurnAndMint_)
    BaseBridgeableToken(
      "Perp88",
      "P88",
      18,
      100_000_000 ether,
      1_000_000_000 ether,
      isBurnAndMint_
    )
  {}
}
