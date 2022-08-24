// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IStaking } from "../../staking/interfaces/IStaking.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
using SafeERC20 for IERC20;

contract MockPLPStaking is IStaking {
  address internal plpTokenAddress;
  address internal maticTokenAddress;
  address internal esp88TokenAddress;
  address internal mockRewarder;

  constructor(
    address _plpTokenAddress,
    address _maticTokenAddress,
    address _esp88TokenAddress
  ) {
    plpTokenAddress = _plpTokenAddress;
    maticTokenAddress = _maticTokenAddress;
    esp88TokenAddress = _esp88TokenAddress;
    mockRewarder = address(1);
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
    uint256 plpAmount = IERC20(plpTokenAddress).balanceOf(address(this));

    IERC20(maticTokenAddress).approve(address(this), plpAmount);
    IERC20(esp88TokenAddress).approve(address(this), plpAmount);

    IERC20(maticTokenAddress).safeTransferFrom(
      address(this),
      address(msg.sender),
      plpAmount
    );

    IERC20(esp88TokenAddress).safeTransferFrom(
      address(this),
      msg.sender,
      plpAmount
    );
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
