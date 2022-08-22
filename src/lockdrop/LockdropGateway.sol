// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ILockdrop } from "./interfaces/ILockdrop.sol";
import { ILockdropGateway } from "./interfaces/ILockdropGateway.sol";

contract LockdropGateway is ILockdropGateway {
  // Claim All Reward Token
  // Pending for Lockdrop contract

  function claimAllRewardGateway(address[] memory _lockdropList, address _user)
    external
  {
    uint256 length = _lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(_lockdropList[index]).claimAllReward(_user);

      unchecked {
        ++index;
      }
    }
  }

  // Claim All P88 Token
  function claimAllP88Gateway(address[] memory _lockdropList, address _user)
    external
  {
    uint256 length = _lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(_lockdropList[index]).claimAllP88(_user);

      unchecked {
        ++index;
      }
    }
  }

  // Withdraw All Deposit Token
  function withdrawAllTokenGateway(
    address[] memory _lockdropList,
    address _user
  ) external {
    uint256 length = _lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(_lockdropList[index]).withdrawAll(_user);

      unchecked {
        ++index;
      }
    }
  }
}
