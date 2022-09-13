// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { RewardDistributor } from "../../staking/RewardDistributor.sol";
import { MockFeedableRewarder } from "../mocks/MockFeedableRewarder.sol";
import { MockPoolForRewardDistributor } from "../mocks/MockPoolForRewardDistributor.sol";
import { MockPoolRouterForRewardDistributor } from "../mocks/MockPoolRouterForRewardDistributor.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console } from "../utils/console.sol";

contract RewardDistributorTest is BaseTest {
  using SafeERC20 for IERC20;

  MockFeedableRewarder internal plpStakingProtocolRevenueRewarder;
  MockFeedableRewarder internal dragonStakingProtocolRevenueRewarder;
  MockErc20 internal wBtc;
  MockErc20 internal wEth;
  MockErc20 internal wMatic;
  MockPoolForRewardDistributor internal pool;
  MockPoolRouterForRewardDistributor internal poolRouter;
  address devFund = address(8888);

  RewardDistributor internal rewardDistributor;

  function setUp() external {
    wBtc = new MockErc20("WBTC", "WBTC", 18);
    wEth = new MockErc20("WETH", "WETH", 18);
    wMatic = new MockErc20("WMATIC", "WMATIC", 18);
    pool = new MockPoolForRewardDistributor();
    poolRouter = new MockPoolRouterForRewardDistributor();

    plpStakingProtocolRevenueRewarder = new MockFeedableRewarder(
      address(wMatic)
    );

    dragonStakingProtocolRevenueRewarder = new MockFeedableRewarder(
      address(wMatic)
    );

    rewardDistributor = deployRewardDistributor(
      address(wMatic),
      address(pool),
      address(poolRouter),
      address(plpStakingProtocolRevenueRewarder),
      address(dragonStakingProtocolRevenueRewarder),
      1200, // 12%
      7500,
      devFund
    );
  }

  // function testRevert_WhenSendInTheTokenToDistributor_ButNotAnOwner() external {
  //   //  Expect Revert
  //   vm.prank(ALICE);
  //   vm.expectRevert("Ownable: caller is not the owner");
  //   rewardDistributor.distributeToken(inTokenList);
  // }

  // function testCorrectness_WhenSendInTheTokenToDistributor_ThenDistibutorSwapTokenToRewardToken()
  //   external
  // {
  //   IERC20(inToken1).safeTransferFrom(
  //     address(this),
  //     address(rewardDistributor),
  //     10 ether
  //   );

  //   IERC20(inToken2).safeTransferFrom(
  //     address(this),
  //     address(rewardDistributor),
  //     10 ether
  //   );

  //   assertEq(IERC20(inToken1).balanceOf(address(rewardDistributor)), 10 ether);
  //   assertEq(IERC20(inToken2).balanceOf(address(rewardDistributor)), 10 ether);
  //   assertEq(
  //     IERC20(rewardToken).balanceOf(address(rewardDistributor)),
  //     0 ether
  //   );

  //   rewardDistributor.distributeToken(inTokenList);

  //   assertEq(IERC20(inToken1).balanceOf(address(rewardDistributor)), 0 ether);
  //   assertEq(IERC20(inToken2).balanceOf(address(rewardDistributor)), 0 ether);
  //   assertEq(
  //     IERC20(rewardToken).balanceOf(address(rewardDistributor)),
  //     2 ether
  //   );
  // }

  function testCorrectness_WhenClaimAndFeedProtocolRevenue() external {
    address[] memory tokens = new address[](3);
    tokens[0] = address(wBtc);
    // tokens.push(wEth);
    // tokens.push(wMatic);

    rewardDistributor.claimAndFeedProtocolRevenue(
      tokens,
      block.timestamp + 3 days
    );
  }
}
