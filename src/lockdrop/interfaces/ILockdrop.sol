// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ILockdrop {
    function lockToken(address _token, uint256 _amount, uint256 _lockPeriod) external;
    function withdrawLockToken(uint256 _amount, address _user) external;
    function claimAllReward(address _user) external;
    function mintPLP() external;
}

