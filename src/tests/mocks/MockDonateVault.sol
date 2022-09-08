// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockDonateVault - For testing purpuse only. DO NOT USE IN PROD.
contract MockDonateVault is ERC20("Some Lending Token", "SLT") {
  address public underlying;

  constructor(address underlying_) {
    underlying = underlying_;
  }

  function deposit(uint256 amount) external {
    ERC20(underlying).transferFrom(msg.sender, address(this), amount);
    uint256 shares = totalSupply() == 0
      ? amount
      : (amount * totalSupply()) / ERC20(underlying).balanceOf(address(this));
    _mint(msg.sender, shares);
  }

  function withdraw(uint256 shares) external {
    uint256 amount = (shares * ERC20(underlying).balanceOf(address(this))) /
      totalSupply();
    _burn(msg.sender, shares);
    ERC20(underlying).transfer(msg.sender, amount);
  }

  function shareToValue(uint256 shares) external view returns (uint256) {
    return
      (shares * ERC20(underlying).balanceOf(address(this))) / totalSupply();
  }

  function valueToShare(uint256 value) external view returns (uint256) {
    return (value * totalSupply()) / ERC20(underlying).balanceOf(address(this));
  }

  function steal(uint256 amount) external {
    ERC20(underlying).transfer(msg.sender, amount);
  }
}
