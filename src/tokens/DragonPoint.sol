// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { BaseMintableToken } from "./base/BaseMintableToken.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DragonPoint is BaseMintableToken {
  mapping(address => bool) public isTransferrer;

  error DragonPoint_isNotTransferrer();

  constructor() BaseMintableToken("Dragon Point", "DP", 18) {}

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

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override(ERC20, IERC20) returns (bool) {
    _transfer(from, to, amount);
    return true;
  }
}
