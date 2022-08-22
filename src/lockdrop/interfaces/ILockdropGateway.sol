// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ILockdropGateway {
  function claimAllStakingContractRewards(
    address[] memory lockdropList,
    address user
  ) external;

  function claimAllP88(address[] memory lockdropList, address user) external;

  function withdrawAllLockedToken(address[] memory lockdropList, address user)
    external;
}
