// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { BaseMintableToken } from "./base/BaseMintableToken.sol";

contract DragonPoint is BaseMintableToken {
  mapping(address => bool) public isTransferrer;

  error DragonPoint_isNotTransferrer();

  constructor()
    BaseMintableToken("Dragon Point", "DP", 18, type(uint256).max)
  {}

  function setTransferrer(address transferrer, bool isActive) external {
    isTransferrer[transferrer] = isActive;
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    if (!isTransferrer[msg.sender]) revert DragonPoint_isNotTransferrer();

    super._transfer(from, to, amount);
  }
}
