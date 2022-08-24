// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";
import { MockRewarder } from "../mocks/MockRewarder.sol";

contract Lockdrop_WithdrawLockToken is Lockdrop_BaseTest {
  MockRewarder internal PRRewarder;

  function setUp() public override {
    super.setUp();
    mockPLPToken.setMinter(address(lockdrop), true);
    PRRewarder = new MockRewarder();
    address[] memory rewarders1 = new address[](1);
    rewarders1[0] = address(PRRewarder);
    plpStaking.addStakingToken(address(mockPLPToken), rewarders1);
  }

  // ------ earlyWithdrawLockedToken ------
  function testCorrectness_LockdropEarlyWithdrawLockToken_WithdrawWithinFirst3Days()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 1 days);
    lockdrop.earlyWithdrawLockedToken(5, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    // After Alice withdraw the ERC20 token from the first 3 days, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 9
    // 2. The amount of Alice's lockdrop token should be 11
    // 3. Alice hasn't claim her P88 so should be false
    // 4. The number of lock period should be 604900
    // 5. The total amount of lock token should be 11
    assertEq(mockERC20.balanceOf(ALICE), 9);
    assertEq(alicelockdropTokenAmount, 11);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 11);
    assertEq(lockdrop.totalP88Weight(), 11 * 604900);
    vm.stopPrank();
  }

  function testCorrectness_LockdropEarlyWithdrawLockToken_MultipleWithdrawWithinFirst3Days()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 1 days);
    lockdrop.earlyWithdrawLockedToken(5, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    // After Alice withdraw the ERC20 token within the first 3 days, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 9
    // 2. The amount of Alice's lockdrop token should be 11
    // 3. Alice hasn't claim her P88 so should be false
    // 4. The number of lock period should be 604900
    // 5. The total amount of lock token should be 11
    assertEq(mockERC20.balanceOf(ALICE), 9);
    assertEq(alicelockdropTokenAmount, 11);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 11);
    assertEq(lockdrop.totalP88Weight(), 11 * 604900);

    vm.warp(lockdropConfig.startLockTimestamp() + 2 days);
    lockdrop.earlyWithdrawLockedToken(11, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    // After Alice withdraw all of her ERC20 token within the first 3 days, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 20
    // 2. Alice is now deleted from lockdropStates so her lock token amount is 0
    // 3. Alice is now deleted from lockdropStates so her lock period is 0
    assertEq(mockERC20.balanceOf(ALICE), 20);
    assertEq(alicelockdropTokenAmount, 0);
    assertEq(alicelockPeriod, 0);
    vm.stopPrank();
  }

  function testCorrectness_LockdropEarlyWithdrawLockToken_WithdrawDay4First12Hours()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 3 days + 2 hours);
    lockdrop.earlyWithdrawLockedToken(5, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    // After Alice withdraw the ERC20 token on day 4 in the first 12 hours, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 9
    // 2. The amount of Alice's lockdrop token should be 11
    // 3. Alice hasn't claim her P88 so should be false
    // 4. The number of lock period should be 604900
    // 5. The total amount of lock token should be 11
    assertEq(mockERC20.balanceOf(ALICE), 9);
    assertEq(alicelockdropTokenAmount, 11);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 11);
    assertEq(lockdrop.totalP88Weight(), 11 * 604900);
  }

  function testCorrectness_LockdropEarlyWithdrawLockToken_WithdrawDay4Last12Hours()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Withdraw timestamp: Day 4 after 12 hours
    vm.warp(lockdropConfig.startLockTimestamp() + 3 days + 18 hours);
    lockdrop.earlyWithdrawLockedToken(4, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    // After Alice withdraw the ERC20 token on day 4 in the last 12 hours, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 8
    // 2. The amount of Alice's lockdrop token should be 12
    // 3. Alice hasn't claim her P88 so should be false
    // 4. The number of lock period should be 604900
    // 5. The total amount of lock token should be 12
    assertEq(mockERC20.balanceOf(ALICE), 8);
    assertEq(alicelockdropTokenAmount, 12);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 12);
    assertEq(lockdrop.totalP88Weight(), 12 * 604900);
  }

  function testRevert_LockdropEarlyWithdrawLockToken_ExceedLockdropPeriod()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.warp(lockdropConfig.startLockTimestamp() + 4 days + 1 hours);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotInLockdropPeriod()"));
    lockdrop.earlyWithdrawLockedToken(5, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawDay4First12HoursInvalidAmount()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);

    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 3 days + 2 hours);
    // Withdraw more than 50%
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidAmount()"));
    lockdrop.earlyWithdrawLockedToken(10, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawDay4Last12HoursInvalidAmount()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);

    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);

    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Withdraw timestamp: Day 4 after 12 hours
    vm.warp(lockdropConfig.startLockTimestamp() + 3 days + 18 hours);
    // Withdraw more than valid amount
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidAmount()"));
    lockdrop.earlyWithdrawLockedToken(5, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawAmountIsZero()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);

    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.warp(lockdropConfig.startLockTimestamp() + 2 days);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_ZeroAmountNotAllowed()"));
    lockdrop.earlyWithdrawLockedToken(0, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawAmountExceedLockAmount()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);

    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.warp(lockdropConfig.startLockTimestamp() + 2 days);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InsufficientBalance()"));
    lockdrop.earlyWithdrawLockedToken(20, ALICE);
    vm.stopPrank();
  }

  // ------ withdrawAll ------
  function testCorrectness_LockdropWithdrawAll() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);
    vm.stopPrank();

    vm.warp(lockdropConfig.endLockTimestamp() + 604900);
    vm.startPrank(address(lockdrop), address(lockdrop));
    mockPLPToken.mint(address(lockdrop), 20);
    mockERC20.approve(address(strategy), 100);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 20);
    lockdrop.stakePLP();
    vm.stopPrank();

    vm.startPrank(ALICE, ALICE);
    lockdrop.withdrawAll(ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();

    // After Alice withdrawAll, the following criteria needs to satisfy:
    // 1. Balance of Alice's PLP token should be 20
    // 2. Balance of lockdrop PLP token should be 0
    // 3. Since Alice is the only one who lock the token, the total amount of PLP token in the contract should remain the same
    // 4. Alice is now deleted from lockdropStates so her lock token amount is 0
    // 5. Alice is now deleted from lockdropStates so her lock period is 0
    assertEq(mockPLPToken.balanceOf(ALICE), 20);
    assertEq(mockPLPToken.balanceOf(address(lockdrop)), 0);
    assertEq(alicelockdropTokenAmount, 0);
    assertEq(alicelockPeriod, 0);
  }

  function testRevert_LockdropWithdrawAll_WithdrawAllBeforeEndOfLockdropHaveZeroPLP()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.expectRevert(abi.encodeWithSignature("Lockdrop_ZeroTotalPLPAmount()"));
    lockdrop.withdrawAll(ALICE);
  }
}
