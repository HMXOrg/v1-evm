// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MintableToken is ERC20, Ownable {
  mapping (address => bool) public isMinter;

  function setMinter(address minter, bool isActive) external onlyOwner {
    isMinter[minter] = isActive;
  }

  function mint(address account, uint256 amount) external {
    require(isMinter[msg.sender], "MintableToken: forbidden");
    super._mint(account, amount);
  }
}