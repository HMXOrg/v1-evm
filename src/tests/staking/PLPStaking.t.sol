// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest, console } from "../base/BaseTest.sol";
import { PLPStaking } from "../../staking/PLPStaking.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { MockRewarder } from "../mocks/MockRewarder.sol";

contract StakingTest is BaseTest {
  PLPStaking internal staking;

  MockErc20 internal plp;
  MockErc20 internal p168;

  MockRewarder internal PRRewarder;
  MockRewarder internal esP88Rewarder;
  MockRewarder internal PRewarder;

  function setUp() external {
    plp = new MockErc20("PLP", "PLP", 18);
    p168 = new MockErc20("P168", "P168", 18);

    PRRewarder = new MockRewarder();
    esP88Rewarder = new MockRewarder();
    PRewarder = new MockRewarder();

    address[] memory rewarders1 = new address[](3);
    rewarders1[0] = address(PRRewarder);
    rewarders1[1] = address(esP88Rewarder);
    rewarders1[2] = address(PRewarder);

    staking = new PLPStaking();
    staking.addStakingToken(address(plp), rewarders1);

    plp.mint(ALICE, 100 ether);
    plp.mint(BOB, 100 ether);
    p168.mint(BOB, 100 ether);
  }

  function test_WhenAliceDeposit_NotStakingToken_ShouldFail() external {
    vm.expectRevert(abi.encodeWithSignature("Staking_isNotStakingToken()"));
    vm.prank(ALICE);
    staking.deposit(ALICE, address(p168), 100 ether);
  }

  function test_WhenAliceDeposit_InsufficientAllowance_ShouldFail() external {
    vm.startPrank(ALICE);
    vm.expectRevert("ERC20: insufficient allowance");
    staking.deposit(ALICE, address(plp), 100 ether);
    vm.stopPrank();
  }

  function test_WhenAliceDeposit_InsufficientBalance_ShouldFail() external {
    vm.startPrank(ALICE);
    plp.approve(address(staking), 200 ether);
    vm.expectRevert("ERC20: transfer amount exceeds balance");
    staking.deposit(ALICE, address(plp), 200 ether);
    vm.stopPrank();
  }

  function test_WhenAliceBobDeposit_ShouldWork() external {
    vm.startPrank(BOB);
    plp.approve(address(staking), 100 ether);
    staking.deposit(BOB, address(plp), 100 ether);
    vm.stopPrank();

    assertEq(plp.balanceOf(BOB), 0);
    assertEq(staking.userTokenAmount(address(plp), BOB), 100 ether);

    assertEq(staking.calculateShare(address(PRRewarder), BOB), 100 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), BOB), 100 ether);
    assertEq(staking.calculateShare(address(PRewarder), BOB), 100 ether);

    assertEq(staking.calculateTotalShare(address(PRRewarder)), 100 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 100 ether);
    assertEq(staking.calculateTotalShare(address(PRewarder)), 100 ether);

    vm.startPrank(ALICE);
    plp.approve(address(staking), 100 ether);
    staking.deposit(ALICE, address(plp), 100 ether);
    vm.stopPrank();

    assertEq(plp.balanceOf(ALICE), 0);
    assertEq(staking.userTokenAmount(address(plp), ALICE), 100 ether);

    assertEq(staking.calculateShare(address(PRRewarder), ALICE), 100 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), ALICE), 100 ether);
    assertEq(staking.calculateShare(address(PRewarder), ALICE), 100 ether);

    assertEq(staking.calculateTotalShare(address(PRRewarder)), 200 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 200 ether);
    assertEq(staking.calculateTotalShare(address(PRewarder)), 200 ether);
  }

  function test_WhenAliceWithdraw_NotStakingToken_ShouldFail() external {
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("Staking_isNotStakingToken()"));
    staking.withdraw(ALICE, address(p168), 100 ether);
    vm.stopPrank();
  }

  function test_WhenAliceWithdraw_InsufficientBalance_ShouldFail() external {
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("Staking_Insufficient()"));
    staking.withdraw(ALICE, address(plp), 100 ether);
    vm.stopPrank();
  }

  function test_WhenAliceBobWithdraw_ShouldWork() external {
    vm.startPrank(BOB);
    plp.approve(address(staking), 100 ether);
    staking.deposit(BOB, address(plp), 100 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    plp.approve(address(staking), 100 ether);
    staking.deposit(ALICE, address(plp), 100 ether);
    vm.stopPrank();

    vm.prank(BOB);
    staking.withdraw(BOB, address(plp), 50 ether);

    assertEq(plp.balanceOf(BOB), 50 ether);
    assertEq(staking.userTokenAmount(address(plp), BOB), 50 ether);

    assertEq(staking.calculateShare(address(PRRewarder), BOB), 50 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), BOB), 50 ether);
    assertEq(staking.calculateShare(address(PRewarder), BOB), 50 ether);

    assertEq(staking.calculateTotalShare(address(PRRewarder)), 150 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 150 ether);
    assertEq(staking.calculateTotalShare(address(PRewarder)), 150 ether);

    vm.prank(ALICE);
    staking.withdraw(ALICE, address(plp), 100 ether);

    assertEq(plp.balanceOf(ALICE), 100 ether);
    assertEq(staking.userTokenAmount(address(plp), ALICE), 0 ether);

    assertEq(staking.calculateShare(address(PRRewarder), ALICE), 0 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), ALICE), 0 ether);
    assertEq(staking.calculateShare(address(PRewarder), ALICE), 0 ether);

    assertEq(staking.calculateTotalShare(address(PRRewarder)), 50 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 50 ether);
    assertEq(staking.calculateTotalShare(address(PRewarder)), 50 ether);
  }

  function test_WhenAddStakingTokenRewarder_ShouldWork() external {
    vm.startPrank(BOB);
    plp.approve(address(staking), 100 ether);
    staking.deposit(BOB, address(plp), 100 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    plp.approve(address(staking), 100 ether);
    staking.deposit(ALICE, address(plp), 100 ether);
    vm.stopPrank();

    address[] memory rewarders = new address[](3);
    rewarders[0] = address(PRRewarder);
    rewarders[1] = address(esP88Rewarder);
    rewarders[2] = address(PRewarder);
    staking.addStakingToken(address(p168), rewarders);

    vm.startPrank(BOB);
    p168.approve(address(staking), 100 ether);
    staking.deposit(BOB, address(p168), 100 ether);
    vm.stopPrank();

    assertEq(plp.balanceOf(BOB), 0);
    assertEq(staking.userTokenAmount(address(p168), BOB), 100 ether);

    assertEq(staking.calculateShare(address(PRRewarder), BOB), 200 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), BOB), 200 ether);
    assertEq(staking.calculateShare(address(PRewarder), BOB), 200 ether);

    assertEq(staking.calculateShare(address(PRRewarder), ALICE), 100 ether);
    assertEq(staking.calculateShare(address(esP88Rewarder), ALICE), 100 ether);
    assertEq(staking.calculateShare(address(PRewarder), ALICE), 100 ether);

    assertEq(staking.calculateTotalShare(address(PRRewarder)), 300 ether);
    assertEq(staking.calculateTotalShare(address(esP88Rewarder)), 300 ether);
    assertEq(staking.calculateTotalShare(address(PRewarder)), 300 ether);
  }

  function test_WhenAddPartnerRewarder_ShouldWork() external {
    MockRewarder P2Rewarder = new MockRewarder();
    address[] memory tokens = new address[](1);
    tokens[0] = address(plp);

    vm.startPrank(BOB);
    plp.approve(address(staking), 100 ether);
    staking.deposit(BOB, address(plp), 100 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    plp.approve(address(staking), 100 ether);
    staking.deposit(ALICE, address(plp), 100 ether);
    vm.stopPrank();

    staking.addRewarder(address(P2Rewarder), tokens);

    assertEq(staking.calculateShare(address(P2Rewarder), ALICE), 100 ether);
    assertEq(staking.calculateShare(address(P2Rewarder), BOB), 100 ether);

    assertEq(staking.calculateTotalShare(address(P2Rewarder)), 200 ether);
  }
}
