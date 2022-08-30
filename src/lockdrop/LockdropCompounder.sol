// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IStaking } from "../staking/interfaces/IStaking.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LockdropCompounder is Ownable, ReentrancyGuard {
  // --- Libraries ---
    using SafeERC20 for IERC20;

  // --- Events ---
  event LogCompound(address indexed user, uint256 amount);

  // --- Custom Errors ---
  error LockdropCompounder_NoESP88();

  // --- States ---
  address public esp88Token;
  IStaking public plpStaking;

  constructor(address esp88Token_, IStaking plpStaking_) {
    esp88Token = esp88Token_;
    plpStaking = plpStaking_;
  }

  // Send to PLP staking
  function compound() external {
    if (IERC20(esp88Token).balanceOf(msg.sender) == 0) revert LockdropCompounder_NoESP88();
    uint256 amount = IERC20(esp88Token).balanceOf(msg.sender);
    plpStaking.deposit(msg.sender, esp88Token, amount);
  }
}
