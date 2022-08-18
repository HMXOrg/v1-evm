// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ILockdrop } from "./ILockdrop.sol";

interface ILockdropGateway {
  function claimAllReward(address[] memory _lockdropList, address _user)
    external;

  function withdrawLockedToken(
    uint256 _amount,
    address[] memory _lockdropList,
    address _user
  ) external;
}
