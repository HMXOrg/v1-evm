// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { DragonStaking } from "../../staking/DragonStaking.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { MockRewarder } from "../mocks/MockRewarder.sol";

contract DragonStakingTest is BaseTest {
  DragonStaking internal staking;

  MockErc20 internal p88;
  MockErc20 internal esP88;
  MockErc20 internal dp;

  MockRewarder internal prRewarder;
  MockRewarder internal esP88Rewarder;
  MockRewarder internal dpRewarder;
  MockRewarder internal pRewarder;

  function setUp() external {
    p88 = new MockErc20("P88", "P88", 18);
    esP88 = new MockErc20("esP88", "esP88", 18);
    dp = new MockErc20("DP", "DP", 18);

    prRewarder = new MockRewarder();
    esP88Rewarder = new MockRewarder();
    dpRewarder = new MockRewarder();
    pRewarder = new MockRewarder();

    address[] memory rewarders1 = new address[](4);
    rewarders1[0] = address(prRewarder);
    rewarders1[1] = address(esP88Rewarder);
    rewarders1[2] = address(dpRewarder);
    rewarders1[3] = address(pRewarder);
    address[] memory rewarders2 = new address[](2);
    rewarders2[0] = address(prRewarder);
    rewarders2[1] = address(pRewarder);

    staking = deployDragonStaking(address(dp));
    staking.addStakingToken(address(p88), rewarders1);
    staking.addStakingToken(address(esP88), rewarders1);
    staking.addStakingToken(address(dp), rewarders2);

    staking.setDragonPointRewarder(address(dpRewarder));

    p88.mint(ALICE, 100 ether);
    esP88.mint(BOB, 100 ether);
    dp.mint(ALICE, 100 ether);
    dp.mint(BOB, 100 ether);
  }

  function testCorrectness_WhenAliceBobDeposit() external {
    vm.startPrank(BOB);
    dp.approve(address(staking), 100 ether);
    staking.deposit(BOB, address(dp), 100 ether);
    vm.stopPrank();

    assertEq(dp.balanceOf(BOB), 0);
    assertEq(staking.userTokenAmount(address(dp), BOB), 100 ether);

    assertEq(staking.calculateShare(address(prRewarder), BOB), 100 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), BOB), 0 ether);
    assertEq(staking.calculateShare(address(dpRewarder), BOB), 0 ether);
    assertEq(staking.calculateShare(address(pRewarder), BOB), 100 ether);

    assertEq(staking.calculateTotalShare(address(prRewarder)), 100 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 0 ether);
    assertEq(staking.calculateTotalShare(address(dpRewarder)), 0 ether);
    assertEq(staking.calculateTotalShare(address(pRewarder)), 100 ether);

    vm.startPrank(ALICE);
    p88.approve(address(staking), 100 ether);
    staking.deposit(ALICE, address(p88), 100 ether);
    vm.stopPrank();

    assertEq(p88.balanceOf(ALICE), 0);
    assertEq(staking.userTokenAmount(address(p88), ALICE), 100 ether);

    assertEq(staking.calculateShare(address(prRewarder), ALICE), 100 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), ALICE), 100 ether);
    assertEq(staking.calculateShare(address(dpRewarder), ALICE), 100 ether);
    assertEq(staking.calculateShare(address(pRewarder), ALICE), 100 ether);

    assertEq(staking.calculateTotalShare(address(prRewarder)), 200 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 100 ether);
    assertEq(staking.calculateTotalShare(address(dpRewarder)), 100 ether);
    assertEq(staking.calculateTotalShare(address(pRewarder)), 200 ether);
  }

  function testCorrectness_WhenAliceBobWithdraw() external {
    vm.startPrank(BOB);
    dp.approve(address(staking), 100 ether);
    staking.deposit(BOB, address(dp), 100 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    p88.approve(address(staking), 100 ether);
    staking.deposit(ALICE, address(p88), 100 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    dp.approve(address(staking), 100 ether);
    staking.deposit(ALICE, address(dp), 100 ether);
    vm.stopPrank();

    vm.prank(BOB);
    staking.withdraw(BOB, address(dp), 50 ether);

    assertEq(dp.balanceOf(BOB), 0 ether);
    assertEq(staking.userTokenAmount(address(dp), BOB), 0 ether);

    assertEq(staking.calculateShare(address(prRewarder), BOB), 0 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), BOB), 0 ether);
    assertEq(staking.calculateShare(address(dpRewarder), BOB), 0 ether);
    assertEq(staking.calculateShare(address(pRewarder), BOB), 0 ether);

    assertEq(staking.calculateTotalShare(address(prRewarder)), 200 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 100 ether);
    assertEq(staking.calculateTotalShare(address(dpRewarder)), 100 ether);
    assertEq(staking.calculateTotalShare(address(pRewarder)), 200 ether);

    vm.prank(ALICE);
    staking.withdraw(ALICE, address(p88), 100 ether);

    assertEq(p88.balanceOf(ALICE), 100 ether);
    assertEq(staking.userTokenAmount(address(p88), ALICE), 0 ether);
    assertEq(dp.balanceOf(ALICE), 0 ether);
    assertEq(staking.userTokenAmount(address(dp), ALICE), 0 ether);

    assertEq(staking.calculateShare(address(prRewarder), ALICE), 0 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), ALICE), 0 ether);
    assertEq(staking.calculateShare(address(dpRewarder), ALICE), 0 ether);
    assertEq(staking.calculateShare(address(pRewarder), ALICE), 0 ether);

    assertEq(staking.calculateTotalShare(address(prRewarder)), 0 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 0 ether);
    assertEq(staking.calculateTotalShare(address(dpRewarder)), 0 ether);
    assertEq(staking.calculateTotalShare(address(pRewarder)), 0 ether);
  }
}
