// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { BaseMintableToken } from "./base/BaseMintableToken.sol";

contract DragonPoint is BaseMintableToken {
  mapping(address => bool) public isTransferrer;

  error DragonPoint_isNotTransferrable();

  constructor() BaseMintableToken("Dragon Point", "DP", 18) {}

  function setTransferrer(address transferrer, bool isActive) external {
    isTransferrer[transferrer] = isActive;
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    if (!(isTransferrer[from] && isTransferrer[to]))
      revert DragonPoint_isNotTransferrable();

    super._transfer(from, to, amount);
  }
}
