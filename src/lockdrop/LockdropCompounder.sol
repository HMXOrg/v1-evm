// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ILockdrop } from "./interfaces/ILockdrop.sol";
import { IStaking } from "../staking/interfaces/IStaking.sol";

contract LockdropCompounder is Ownable, ReentrancyGuard {
  // --- Libraries ---
  using SafeERC20 for IERC20;

  // --- Events ---
  event LogCompound(address indexed user, uint256 amount);

  // --- Custom Errors ---
  error LockdropCompounder_NoESP88();

  // --- States ---
  address public esp88Token;
  address public dragonStaking;

  constructor(address esp88Token_, address dragonStaking_) {
    esp88Token = esp88Token_;
    dragonStaking = dragonStaking_;
  }

  function _claimAll(address[] memory lockdrops, address user) internal {
    uint256 length = lockdrops.length;
    for (uint256 i = 0; i < length; ) {
      ILockdrop(lockdrops[i]).claimAllRewards(user);
      unchecked {
        ++i;
      }
    }
  }

  // Send to PLP staking
  function compound(address[] memory lockdrops) external {
    _claimAll(lockdrops, msg.sender);
    uint256 amount = IERC20(esp88Token).balanceOf(msg.sender);
    IERC20(esp88Token).safeTransferFrom(msg.sender, address(this), amount);
    IStaking(dragonStaking).deposit(msg.sender, esp88Token, amount);
    emit LogCompound(msg.sender, amount);
  }
}
