// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ILockdropGateway {
  function claimAllRewardGateway(address[] memory _lockdropList, address _user)
    external;

  function claimAllP88Gateway(address[] memory _lockdropList, address _user)
    external;

  function withdrawAllTokenGateway(
    address[] memory _lockdropList,
    address _user
  ) external;
}
