// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { MintableTokenInterface } from "../../interfaces/MintableTokenInterface.sol";

contract BaseMintableToken is Ownable, ERC20, MintableTokenInterface {
  error BaseMintableToken_NotMinter();

  uint8 private _decimals;
  mapping(address => bool) public isMinter;

  event SetMinter(address minter, bool prevAllow, bool newAllow);

  constructor(
    string memory name,
    string memory symbol,
    uint8 __decimals
  ) ERC20(name, symbol) {
    _decimals = __decimals;
  }

  modifier onlyMinter() {
    if (!isMinter[msg.sender]) revert BaseMintableToken_NotMinter();
    _;
  }

  function setMinter(address minter, bool allow) external override onlyOwner {
    emit SetMinter(minter, isMinter[minter], allow);
    isMinter[minter] = allow;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function mint(address to, uint256 amount) public override onlyMinter {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public override onlyMinter {
    _burn(from, amount);
  }
}
