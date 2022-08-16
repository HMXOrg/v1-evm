// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { Rewarder } from "../../staking/Rewarder.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { MockStaking } from "../mocks/MockStaking.sol";

contract RewarderTest is BaseTest {
  Rewarder internal rewarder;
  MockErc20 internal rewardToken;
  MockStaking internal mockStaking;

  function setUp() external {
    mockStaking = new MockStaking();

    rewardToken = new MockErc20("Reward Token", "REW", 18);
    rewarder = new Rewarder(
      "REWRewarder",
      address(rewardToken),
      address(mockStaking)
    );

    rewardToken.mint(address(this), 1000000 ether);
    rewardToken.approve(address(rewarder), 1000000 ether);
  }

  function test_WhenRewarderIsInit_ShouldBeCorrectlyInit() external {
    assertEq(rewarder.name(), "REWRewarder");
    assertEq(rewarder.rewardToken(), address(rewardToken));
    assertEq(rewarder.lastRewardTime(), block.timestamp);
  }

  function test_WhenRewarderOnDepositIsHooked_ShouldWorkCorrectly() external {
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

  function test_WhenAliceAndBobDeposit_ShouldHarvestTokenCorrectly() external {
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

  function test_WhenAliceAndBobDeposit_ThenAliceWithdraw_ShouldHarvestTokenCorrectly()
    external
  {
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

  function test_WhenAliceAndBobDepositSimpultaneously_ThenBothWithdrawSimpultaneously_ShouldHarvestTokenEqually()
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

  function test_WhenAliceDeposit_ThenWithdraw_ThenRedeposit_ShouldHarvestTokenCorrectly()
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
    assertEq(rewardToken.balanceOf(ALICE), 9999.999999999980000000 ether);
  }
}
