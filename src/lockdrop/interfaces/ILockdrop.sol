// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ILockdrop {
  function lockToken(uint256 amount, uint256 lockPeriod) external;

  function extendLockPeriod(uint256 lockPeriod) external;

  function addLockAmount(uint256 amount) external;

  function earlyWithdrawLockedToken(uint256 amount, address user) external;

  function claimAllRewards(address user) external;

  function stakePLP() external;

  function withdrawAll(address user) external;

  function claimAllP88(address user) external;
}
