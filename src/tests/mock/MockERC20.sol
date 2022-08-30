// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(string memory name_, string memory symbol_)
    public
    ERC20(name_, symbol_)
  {}

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}
