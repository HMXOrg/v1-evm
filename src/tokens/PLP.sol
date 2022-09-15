// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { BaseMintableToken } from "./base/BaseMintableToken.sol";

contract PLP is BaseMintableToken {
  mapping(address => bool) public isTransferrer;
  mapping(address => uint256) public cooldown;

  error PLP_BadCooldownExpireAt(uint256 cooldownExpireAt);
  error PLP_Cooldown(uint256 cooldownExpireAt);
  error PLP_isNotTransferrer();

  constructor() BaseMintableToken("P88 Liquidity Provider", "PLP", 18) {}

  function setTransferrer(address transferrer, bool isActive) external {
    isTransferrer[transferrer] = isActive;
  }

  function mint(
    address to,
    uint256 amount,
    uint256 cooldownExpireAt
  ) public onlyMinter {
    if (cooldownExpireAt < block.timestamp)
      revert PLP_BadCooldownExpireAt(cooldownExpireAt);
    cooldown[to] = cooldownExpireAt;
    _mint(to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    uint256 cooldownExpireAt = cooldown[from];
    if (
      (amount > 0 && !isTransferrer[from] && !isTransferrer[to]) &&
      block.timestamp < cooldownExpireAt
    ) revert PLP_Cooldown(cooldownExpireAt);
  }
}
