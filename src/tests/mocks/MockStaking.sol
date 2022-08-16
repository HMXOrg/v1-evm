// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IRewarder } from "../../staking/interfaces/IRewarder.sol";
import { IStaking } from "../../staking/interfaces/IStaking.sol";

contract MockStaking is IStaking {
  uint256 totalShare;
  mapping(address => uint256) shares;

  function deposit(
    address rewarder,
    address user,
    uint256 shareAmount
  ) public {
    IRewarder(rewarder).onDeposit(user, shareAmount);
    totalShare += shareAmount;
    shares[user] += shareAmount;
  }

  function withdraw(
    address rewarder,
    address user,
    uint256 shareAmount
  ) public {
    IRewarder(rewarder).onWithdraw(user, shareAmount);
    totalShare -= shareAmount;
    shares[user] -= shareAmount;
  }

  function harvest(address rewarder, address user) public {
    IRewarder(rewarder).onHarvest(user);
  }

  function calculateTotalShare(address rewarder)
    external
    view
    returns (uint256)
  {
    return totalShare;
  }

  function calculateShare(address rewarder, address user)
    external
    view
    returns (uint256)
  {
    return shares[user];
  }

  function isRewarder(address rewarder) external view returns (bool) {
    return false;
  }
}
