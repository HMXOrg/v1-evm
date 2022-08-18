// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ILockdrop {
  function lockToken(
    uint256 _amount,
    uint256 _lockPeriod
  ) external;

  function earlyWithdrawLockedToken(uint256 _amount, address _user) external;

  function claimAllReward(address _user) external;

  function stakePLP() external;

  function withdrawAll(address _user) external;

  function claimAllP88(address _user) external;
}
