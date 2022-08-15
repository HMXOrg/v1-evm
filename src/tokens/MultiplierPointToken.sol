// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./MintableToken.sol";
import "./BurnableToken.sol";

contract MultiplierPointToken is MintableToken, BurnableToken {
  mapping(address => bool) public isTransferrer;

  error MultiplierPointToken_isNotTransferrable();

  constructor() ERC20("Multiplier Point Token", "MPT") {}

  function setTransferrer(address transferrer, bool isActive) external {
    isTransferrer[transferrer] = isActive;
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    if (!(isTransferrer[from] && isTransferrer[to]))
      revert MultiplierPointToken_isNotTransferrable();

    super._transfer(from, to, amount);
  }
}
