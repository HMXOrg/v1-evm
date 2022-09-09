// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { FeedableRewarder } from "../../staking/FeedableRewarder.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { MockStaking } from "../mocks/MockStaking.sol";
import { console } from "../utils/console.sol";
import { math } from "../utils/math.sol";

contract FeedableRewarderTest is BaseTest {
  FeedableRewarder internal rewarder;
  MockErc20 internal rewardToken;
  MockStaking internal mockStaking;

  function setUp() external {
    mockStaking = new MockStaking();

    rewardToken = new MockErc20("Reward Token", "REW", 18);
    rewarder = deployFeedableRewarder(
      "REWRewarder",
      address(rewardToken),
      address(mockStaking)
    );

    rewardToken.mint(address(this), 2 * 1e12 ether);
    rewardToken.approve(address(rewarder), 2 * 1e12 ether);
  }

  function testCorrectness_WhenRewarderIsInit() external {
    assertEq(rewarder.name(), "REWRewarder");
    assertEq(rewarder.rewardToken(), address(rewardToken));
    assertEq(rewarder.lastRewardTime(), block.timestamp);
  }

  function testRevert_WhenHookIsCalled_BySomeRandomGuy() external {
    vm.startPrank(ALICE);

    vm.expectRevert(
      abi.encodeWithSignature("FeedableRewarderError_NotStakingContract()")
    );
    rewarder.onDeposit(BOB, 1 ether);

    vm.expectRevert(
      abi.encodeWithSignature("FeedableRewarderError_NotStakingContract()")
    );
    rewarder.onWithdraw(BOB, 1 ether);

    vm.expectRevert(
      abi.encodeWithSignature("FeedableRewarderError_NotStakingContract()")
    );
    rewarder.onHarvest(BOB, CAT);

    vm.stopPrank();
  }

  function testRevert_WhenFeedIsCalled_BySomeRandomGuy() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    rewarder.feed(1 ether, 1 days);

    vm.expectRevert("Ownable: caller is not the owner");
    rewarder.feedWithExpiredAt(1 ether, block.timestamp + 1 days);

    vm.stopPrank();
  }

  function testCorrectness_WhenRewarderOnDepositIsHooked() external {
    // feed and amount of token
    // rewardPerSec ~= 0.033068783068783068
    rewarder.feed(20000 ether, 7 days);

    // time has not pass, acc reward = 0, reward debt = 0
    assertEq(rewarder.lastRewardTime(), block.timestamp);
    assertEq(rewarder.accRewardPerShare(), 0);
    assertEq(rewarder.userRewardDebts(ALICE), 0);
    mockStaking.deposit(address(rewarder), ALICE, 88 ether);
    assertEq(rewarder.lastRewardTime(), block.timestamp);
    assertEq(rewarder.accRewardPerShare(), 0);
    assertEq(rewarder.userRewardDebts(ALICE), 0);

    // after 1 hour, acc reward should be calculated correctly
    vm.warp(block.timestamp + 1 hours);
    mockStaking.deposit(address(rewarder), ALICE, 188 ether);
    // 3600 * 0.033068783068783068 * 1e-6 / 88 = 0.000001352813852813
    assertEq(rewarder.accRewardPerShare(), 0.000001352813852813 ether);
    // 188 * 0.000001352813852813
    assertEq(rewarder.userRewardDebts(ALICE), 254.329004328844 ether);

    // // after 3 hours, acc reward should be calculated correctly
    vm.warp(block.timestamp + 3 hours);
    mockStaking.deposit(address(rewarder), ALICE, 23 ether);
    // 0.000001352813852813 + [(3600 * 3) * 0.033068783068783068 * 1e-6 / 276] = 0.000002646809712026
    assertEq(rewarder.accRewardPerShare(), 0.000002646809712026 ether);
    // 254.329004328844 + (23 * 2.646809712026) = 315.205627705442
    assertEq(rewarder.userRewardDebts(ALICE), 315.205627705442 ether);
  }

  function testCorrectness_WhenAliceAndBobDeposit() external {
    // feed and amount of token
    rewarder.feed(20000 ether, 10 days);

    // ALICE deposit 10 shares
    mockStaking.deposit(address(rewarder), ALICE, 10 ether);

    // After 5 days, BOB deposit 10 shares
    vm.warp(block.timestamp + 5 days);
    mockStaking.deposit(address(rewarder), BOB, 10 ether);

    // After another 5 days, both harvest
    // ALICE should get ~15000 REW
    // BOB should get ~5000 REW
    vm.warp(block.timestamp + 5 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    assertEq(rewardToken.balanceOf(BOB), 0);
    mockStaking.harvest(address(rewarder), ALICE);
    mockStaking.harvest(address(rewarder), BOB);
    assertEq(rewardToken.balanceOf(ALICE), 14999.999999999980000000 ether);
    assertEq(rewardToken.balanceOf(BOB), 4999.999999999990000000 ether);
  }

  function testCorrectness_WhenAliceAndBobDeposit_ThenAliceWithdraw() external {
    // feed and amount of token
    rewarder.feed(20000 ether, 20 days);

    // ALICE deposit 10 shares
    mockStaking.deposit(address(rewarder), ALICE, 10 ether);

    // After 5 days, BOB deposit 10 shares
    vm.warp(block.timestamp + 5 days);
    mockStaking.deposit(address(rewarder), BOB, 10 ether);

    // After another 10 days, ALICE withdraw 10 shares
    vm.warp(block.timestamp + 10 days);
    mockStaking.withdraw(address(rewarder), ALICE, 10 ether);

    // After another 5 days, both harvest
    // ALICE should get ~10000 REW
    // BOB should get ~10000 REW
    vm.warp(block.timestamp + 5 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    assertEq(rewardToken.balanceOf(BOB), 0);
    mockStaking.harvest(address(rewarder), ALICE);
    mockStaking.harvest(address(rewarder), BOB);
    assertEq(rewardToken.balanceOf(ALICE), 9999.999999999980000000 ether);
    assertEq(rewardToken.balanceOf(BOB), 9999.999999999980000000 ether);
  }

  function testCorrectness_WhenAliceAndBobDepositSimpultaneously_ThenBothWithdrawSimpultaneously()
    external
  {
    // feed and amount of token
    rewarder.feed(20000 ether, 20 days);

    // ALICE deposit 10 shares
    mockStaking.deposit(address(rewarder), ALICE, 10 ether);
    mockStaking.deposit(address(rewarder), BOB, 10 ether);

    // After 21 days, both harvest (1 day after reward end)
    vm.warp(block.timestamp + 21 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    assertEq(rewardToken.balanceOf(BOB), 0);
    mockStaking.harvest(address(rewarder), ALICE);
    mockStaking.harvest(address(rewarder), BOB);
  }

  function testCorrectness_WhenAliceDeposit_ThenWithdraw_ThenRedeposit()
    external
  {
    // feed and amount of token
    rewarder.feed(20000 ether, 20 days);

    // ALICE deposit 10 shares
    mockStaking.deposit(address(rewarder), ALICE, 10 ether);

    // After 5 days, ALICE withdraw
    vm.warp(block.timestamp + 5 days);
    mockStaking.withdraw(address(rewarder), ALICE, 10 ether);

    // After 10 days, ALICE redeposit
    vm.warp(block.timestamp + 10 days);
    mockStaking.deposit(address(rewarder), ALICE, 10 ether);

    // After 5 days, ALICE harvest
    // ALICE should get ~10000 REW
    vm.warp(block.timestamp + 5 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    mockStaking.harvest(address(rewarder), ALICE);
    assertEq(rewardToken.balanceOf(ALICE), 19999.999999999980000000 ether);
  }

  function test_WhenFeedTokenMultipleTimes() external {
    // DAY#0
    // feed and amount of token
    rewarder.feed(20000 ether, 20 days);

    // ALICE deposit 10 shares
    mockStaking.deposit(address(rewarder), ALICE, 10 ether);

    // DAY#9
    // After 9 days, feed more reward
    vm.warp(block.timestamp + 9 days);
    rewarder.feed(45000 ether, 25 days);

    // DAY#16
    // After 7 days, harvest
    // From the first 9 days, ALICE should get 45% of first 20000 REW.
    // Then the next 7 days, ALICE should get 28% of (leftover 11000 REW + 45000 REW)
    // Hence, ALICE should get 9000 REW + 15680 REW = 24680 REW.
    vm.warp(block.timestamp + 7 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    mockStaking.harvest(address(rewarder), ALICE);
    assertEq(rewardToken.balanceOf(ALICE), 24679.999999999980000000 ether);
  }

  function testCorrectness_WhenFeedTokenMultipleTimes_WithAliceAndBobDeposit_ThenAliceWithdraw(
    uint256 feedAmount1,
    uint256 feedAmount2
  ) external {
    vm.assume(feedAmount1 > 0.01 ether);
    vm.assume(feedAmount2 > 0.01 ether);
    vm.assume(feedAmount1 < 1e12 ether);
    vm.assume(feedAmount2 < 1e12 ether);

    // the comment on this test case assumes, the following params
    // uint256 feedAmount1 = 20000 ether;
    // uint256 feedAmount2 = 45000 ether;

    // DAY#0
    // feed and amount of token
    rewarder.feed(feedAmount1, 20 days);

    // ALICE deposit 10 shares
    mockStaking.deposit(address(rewarder), ALICE, 10 ether);
    // BOB deposit 15 shares
    mockStaking.deposit(address(rewarder), BOB, 15 ether);

    // DAY#10
    // After 10 days, feed more reward
    vm.warp(block.timestamp + 10 days);
    rewarder.feed(feedAmount2, 25 days);

    // DAY#12
    // ALICE withdraw 5 shares
    vm.warp(block.timestamp + 2 days);
    mockStaking.withdraw(address(rewarder), ALICE, 5 ether);

    // DAY#15
    // Both harvest
    vm.warp(block.timestamp + 3 days);

    // Day0 to Day10:
    // ALICE vs BOB share = 40:60
    // Reward should be distributed 50% of 20000 REW = 10000 REW
    // ALICE should get 40% of 10000 REW = 4000 REW
    // BOB should get 60% of 10000 REW = 6000 REW
    uint256 aliceReward1 = (((feedAmount1 * 50) / 100) * 40) / 100;
    uint256 bobReward1 = (((feedAmount1 * 50) / 100) * 60) / 100;
    // Then, new portion of reward was added 45000 REW.
    // Total reward: 45000 REW + leftover 10000 REW = 55000 REW

    // Day10 to Day12:
    // Reward should be distributed 8% of 55000 REW = 4400 REW
    // ALICE should get 40% of 4400 REW = 1760 REW
    // BOB should get 60% of 4400 REW = 2640 REW
    uint256 day10Amount = ((feedAmount1 * 50) / 100) + feedAmount2;
    uint256 aliceReward2 = (((day10Amount * 8) / 100) * 40) / 100;
    uint256 bobReward2 = (((day10Amount * 8) / 100) * 60) / 100;
    // Then, ALICE withdraw 5 shares.
    // ALICE vs BOB share = 25:75
    // Total reward: 55000 REW - 4400 REW = 50600 REW

    // Day12 to Day15:
    // Reward should be distributed 13.0434782609% (3/23) of 50600 REW = 6600.0000000154 REW
    // ALICE should get 25% of 6600.0000000154 REW = 1,650.0000000039 REW
    // BOB should get 75% of 6600.0000000154 REW = 4,950.0000000116 REW
    uint256 day12Amount = (day10Amount * 92) / 100;
    uint256 aliceReward3 = (((day12Amount * 3) / 23) * 25) / 100;
    uint256 bobReward3 = (((day12Amount * 3) / 23) * 75) / 100;

    // In total
    // ALICE gets 4000 REW + 1760 REW + 1650.0000000039 REW ~= 7410.0000000039 REW
    // BOB gets 6000 REW + 2640 REW + 4950.0000000116 REW ~= 13590.0000000116 REW
    uint256 aliceTotal = aliceReward1 + aliceReward2 + aliceReward3;
    uint256 bobTotal = bobReward1 + bobReward2 + bobReward3;

    assertEq(rewardToken.balanceOf(ALICE), 0);
    assertTrue(math.almostEqual(rewarder.pendingReward(ALICE), aliceTotal, 1));
    mockStaking.harvest(address(rewarder), ALICE);
    assertTrue(math.almostEqual(rewardToken.balanceOf(ALICE), aliceTotal, 1));

    assertEq(rewardToken.balanceOf(BOB), 0);
    assertTrue(math.almostEqual(rewarder.pendingReward(BOB), bobTotal, 1));
    mockStaking.harvest(address(rewarder), BOB);
    assertTrue(math.almostEqual(rewardToken.balanceOf(BOB), bobTotal, 1));
  }
}
