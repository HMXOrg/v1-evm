// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ILockdrop } from "./interfaces/ILockdrop.sol";

contract LockdropGateway {
  // Claim All P88 Token
  function claimAllReward(address[] memory _lockdropList, address _user)
    external
  {
    for (uint256 index = 0; index < _lockdropList.length; index++) {
      ILockdrop(_lockdropList[index]).claimAllReward(_user);
    }
  }

  // Withdraw All Deposit Token
  function withdrawLockedToken(
    uint256 _amount,
    address[] memory _lockdropList,
    address _user
  ) external {
    for (uint256 index = 0; index < _lockdropList.length; index++) {
      ILockdrop(_lockdropList[index]).withdrawLockToken(_amount, _user);
    }
  }
}
