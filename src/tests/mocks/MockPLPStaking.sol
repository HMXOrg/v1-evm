// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IStaking } from "../../staking/interfaces/IStaking.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";

using SafeERC20 for IERC20;

contract MockPLPStaking is IStaking {
  address internal plpTokenAddress;
  address internal revenueTokenAddress;
  address internal esp88TokenAddress;
  address internal mockRewarder;

  uint256 internal revenueRewardAmount;
  uint256 internal esp88RewardLastReward;
  uint256 internal rewardPerSec;

  constructor(
    address _plpTokenAddress,
    address _revenueTokenAddress,
    address _esp88TokenAddress
  ) {
    plpTokenAddress = _plpTokenAddress;
    revenueTokenAddress = _revenueTokenAddress;
    esp88TokenAddress = _esp88TokenAddress;
    mockRewarder = address(1);
    rewardPerSec = 1 ether;
    esp88RewardLastReward = block.timestamp;
  }

  function deposit(
    address to,
    address token,
    uint256 amount
  ) external {}

  function withdraw(
    address to,
    address token,
    uint256 amount
  ) external {}

  function getUserTokenAmount(address token, address sender)
    external
    returns (uint256)
  {
    return IERC20(plpTokenAddress).balanceOf(address(this));
  }

  function getStakingTokenRewarders(address token)
    external
    returns (address[] memory)
  {
    address[] memory rewarderList = new address[](1);
    rewarderList[0] = mockRewarder;

    return rewarderList;
  }

  function harvest(address[] memory rewarders) external {
    uint256 esp88RewardAmount = (block.timestamp - esp88RewardLastReward) *
      rewardPerSec;

    MockErc20(esp88TokenAddress).mint(msg.sender, esp88RewardAmount);

    IERC20(revenueTokenAddress).approve(address(this), revenueRewardAmount);
    IERC20(revenueTokenAddress).transfer(msg.sender, revenueRewardAmount);
    revenueRewardAmount = 0;

    esp88RewardLastReward = block.timestamp;
  }

  function feedRevenueReward(uint256 tokenAmount) external {
    IERC20(revenueTokenAddress).safeTransferFrom(
      msg.sender,
      address(this),
      tokenAmount
    );

    revenueRewardAmount += tokenAmount;
  }

  function harvestToCompounder(address user, address[] memory rewarders)
    external
  {}

  function calculateTotalShare(address rewarder)
    external
    view
    returns (uint256)
  {}

  function calculateShare(address rewarder, address user)
    external
    view
    returns (uint256)
  {}

  function isRewarder(address rewarder) external view returns (bool) {}
}
