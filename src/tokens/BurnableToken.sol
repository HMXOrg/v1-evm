// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BurnableToken is ERC20, Ownable {
  mapping (address => bool) public isBurner;

  function setBurner(address burner, bool isActive) external onlyOwner {
    isBurner[burner] = isActive;
  }

  function burn(address account, uint256 amount) external {
    require(isBurner[msg.sender], "BurnableToken: forbidden");
    super._burn(account, amount);
  }
}