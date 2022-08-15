// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { Rewarder } from "../../staking/Rewarder.sol";
import { MockERC20 } from "../mock/MockERC20.sol";

contract RewarderTest is BaseTest {
  Rewarder internal rewarder;
  MockERC20 internal rewardToken;

  address public constant ALICE = address(1);
  address public constant BOB = address(2);

  function setUp() external {
    rewardToken = new MockERC20("Reward Token", "REW");
    rewarder = new Rewarder("REWRewarder", address(rewardToken));

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
    rewarder.feed(20000 ether, 7 days, 0);

    // time has not pass, acc reward = 0, reward debt = 0
    assertEq(rewarder.lastRewardTime(), block.timestamp);
    assertEq(rewarder.accRewardPerShare(), 0);
    assertEq(rewarder.userRewardDebts(ALICE), 0);
    rewarder.onDeposit(ALICE, 88 ether, 88 ether);
    assertEq(rewarder.lastRewardTime(), block.timestamp);
    assertEq(rewarder.accRewardPerShare(), 0);
    assertEq(rewarder.userRewardDebts(ALICE), 0);

    // after 1 hour, acc reward should be calculated correctly
    vm.warp(block.timestamp + 1 hours);
    rewarder.onDeposit(ALICE, 188 ether, 276 ether);
    // 3600 * 0.033068783068783068 * 1e-6 / 276 = 0.000000431331953071
    assertEq(rewarder.accRewardPerShare(), 0.000000431331953071 ether);
    // 188 * 0.431331953071
    assertEq(rewarder.userRewardDebts(ALICE), 81.090407177348 ether);

    // after 3 hours, acc reward should be calculated correctly
    vm.warp(block.timestamp + 3 hours);
    rewarder.onDeposit(ALICE, 23 ether, 299 ether);
    // 0.000000431331953071 + [(3600 * 3) * 0.033068783068783068 * 1e-6 / 299] = 0.000001625789669267
    assertEq(rewarder.accRewardPerShare(), 0.000001625789669267 ether);
    // 81.090407177348 + (23 * 1.625789669267) = 118.483569570489
    assertEq(rewarder.userRewardDebts(ALICE), 118.483569570489 ether);
  }

  function test_WhenAliceAndBobDeposit_ShouldHarvestTokenCorrectly() external {
    // feed and amount of token
    rewarder.feed(20000 ether, 10 days, 0);

    // ALICE deposit 10 shares
    rewarder.onDeposit(ALICE, 10 ether, 0 ether);

    // After 5 days, BOB deposit 10 shares
    vm.warp(block.timestamp + 5 days);
    rewarder.onDeposit(BOB, 10 ether, 10 ether);

    // After another 5 days, both harvest
    // ALICE should get ~15000 REW
    // BOB should get ~5000 REW
    vm.warp(block.timestamp + 5 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    assertEq(rewardToken.balanceOf(BOB), 0);
    rewarder.onHarvest(ALICE, 10 ether, 20 ether);
    rewarder.onHarvest(BOB, 10 ether, 20 ether);
    assertEq(rewardToken.balanceOf(ALICE), 14999.999999999980000000 ether);
    assertEq(rewardToken.balanceOf(BOB), 4999.999999999990000000 ether);
  }

  function test_WhenAliceAndBobDeposit_ThenAliceWithdraw_ShouldHarvestTokenCorrectly()
    external
  {
    // feed and amount of token
    rewarder.feed(20000 ether, 20 days, 0);

    // ALICE deposit 10 shares
    rewarder.onDeposit(ALICE, 10 ether, 0 ether);

    // After 5 days, BOB deposit 10 shares
    vm.warp(block.timestamp + 5 days);
    rewarder.onDeposit(BOB, 10 ether, 10 ether);

    // After another 10 days, ALICE withdraw 10 shares
    vm.warp(block.timestamp + 10 days);
    rewarder.onWithdraw(ALICE, 10 ether, 20 ether);

    // After another 5 days, both harvest
    // ALICE should get ~10000 REW
    // BOB should get ~10000 REW
    vm.warp(block.timestamp + 5 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    assertEq(rewardToken.balanceOf(BOB), 0);
    rewarder.onHarvest(ALICE, 0 ether, 10 ether);
    rewarder.onHarvest(BOB, 10 ether, 10 ether);
    assertEq(rewardToken.balanceOf(ALICE), 9999.999999999980000000 ether);
    assertEq(rewardToken.balanceOf(BOB), 9999.999999999980000000 ether);
  }

  function test_WhenAliceAndBobDepositSimpultaneously_ThenBothWithdrawSimpultaneously_ShouldHarvestTokenEqually()
    external
  {
    // feed and amount of token
    rewarder.feed(20000 ether, 20 days, 0);

    // ALICE deposit 10 shares
    rewarder.onDeposit(ALICE, 10 ether, 0 ether);
    rewarder.onDeposit(BOB, 10 ether, 10 ether);

    // After 21 days, both harvest (1 day after reward end)
    vm.warp(block.timestamp + 21 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    assertEq(rewardToken.balanceOf(BOB), 0);
    rewarder.onHarvest(ALICE, 10 ether, 20 ether);
    rewarder.onHarvest(BOB, 10 ether, 20 ether);
  }

  function test_WhenAliceDeposit_ThenWithdraw_ThenRedeposit_ShouldHarvestTokenCorrectly()
    external
  {
    // feed and amount of token
    rewarder.feed(20000 ether, 20 days, 0);

    // ALICE deposit 10 shares
    rewarder.onDeposit(ALICE, 10 ether, 0 ether);

    // After 5 days, ALICE withdraw
    vm.warp(block.timestamp + 5 days);
    rewarder.onWithdraw(ALICE, 10 ether, 10 ether);

    // After 10 days, ALICE redeposit
    vm.warp(block.timestamp + 10 days);
    rewarder.onDeposit(ALICE, 10 ether, 0 ether);

    // After 5 days, ALICE harvest
    // ALICE should get ~10000 REW
    vm.warp(block.timestamp + 5 days);
    assertEq(rewardToken.balanceOf(ALICE), 0);
    rewarder.onHarvest(ALICE, 10 ether, 10 ether);
    assertEq(rewardToken.balanceOf(ALICE), 9999.999999999980000000 ether);
  }
}
