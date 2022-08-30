// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ILockdrop } from "./interfaces/ILockdrop.sol";
import { ILockdropGateway } from "./interfaces/ILockdropGateway.sol";
import { IStaking } from "../staking/interfaces/IStaking.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockdropGateway is ILockdropGateway {
  IERC20 public plpToken;
  IStaking public plpStaking;

  constructor(IERC20 plpToken_, IStaking plpStaking_) {
    plpToken = plpToken_;
    plpStaking = plpStaking_;
  }

  // Claim All Reward Token
  // Pending for Lockdrop contract

  function claimAllStakingContractRewards(
    address[] memory lockdropList,
    address user
  ) external {
    uint256 length = lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(lockdropList[index]).claimAllRewards(user);

      unchecked {
        ++index;
      }
    }
  }

  // Claim All P88 Token
  function claimAllP88(address[] memory lockdropList, address user) external {
    uint256 length = lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(lockdropList[index]).claimAllP88(user);

      unchecked {
        ++index;
      }
    }
  }

  // Withdraw All Deposit Token
  function withdrawAllAndStakePLP(address[] memory lockdropList, address user)
    external
  {
    uint256 length = lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(lockdropList[index]).withdrawAll(user);

      unchecked {
        ++index;
      }
    }

    plpToken.approve(address(plpStaking), plpToken.balanceOf(address(this)));

    plpStaking.deposit(
      user,
      address(plpToken),
      plpToken.balanceOf(address(this))
    );
  }
}
