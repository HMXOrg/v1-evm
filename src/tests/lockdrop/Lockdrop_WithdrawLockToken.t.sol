// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_WithdrawLockToken is Lockdrop_BaseTest {
  function setUp() public override {
    super.setUp();
    mockPLPToken.setMinter(address(this), true);
  }

  // ------ earlyWithdrawLockedToken ------
  function testCorrectness_LockdropEarlyWithdrawLockToken_WithdrawWithinFirst3Days()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(lockAmount, lockPeriod);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 1 days);
    lockdrop.earlyWithdrawLockedToken(5 ether, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw the ERC20 token from the first 3 days, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 9
    // 2. The amount of Alice's lockdrop token should be 11
    // 3. The number of lock period should be 8 days
    // 4. The total amount of lock token should be 11
    // 5. The total weight of P88 should be 11 * 8 days
    assertEq(mockERC20.balanceOf(ALICE), 9 ether);
    assertEq(alicelockdropTokenAmount, 11 ether);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), 11 ether);
    assertEq(lockdrop.totalP88Weight(), 11 ether * lockPeriod);
    vm.stopPrank();
  }

  function testCorrectness_LockdropEarlyWithdrawLockToken_WithdrawAllWithinFirst3Days()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(lockAmount, lockPeriod);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 1 days);
    lockdrop.earlyWithdrawLockedToken(lockAmount, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw the ERC20 token from the first 3 days, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 20
    // 2. The amount of Alice's lockdrop token should be 0
    // 3. The number of lock period should be 0
    // 4. The total amount of lock token should be 0
    // 5. The total weight of P88 should be 0
    assertEq(mockERC20.balanceOf(ALICE), 20 ether);
    assertEq(alicelockdropTokenAmount, 0);
    assertEq(alicelockPeriod, 0);
    assertEq(lockdrop.totalAmount(), 0);
    assertEq(lockdrop.totalP88Weight(), 0);
    vm.stopPrank();
  }

  function testCorrectness_LockdropEarlyWithdrawLockToken_MultipleWithdrawWithinFirst3Days()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 1 days);
    lockdrop.earlyWithdrawLockedToken(5 ether, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw the ERC20 token within the first 3 days, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 9
    // 2. The amount of Alice's lockdrop token should be 11
    // 3. The number of lock period should be 8 days
    // 4. The total amount of lock token should be 11
    // 5. The total weight of P88 should be 11 * 8 days
    assertEq(mockERC20.balanceOf(ALICE), 9 ether);
    assertEq(alicelockdropTokenAmount, 11 ether);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), 11 ether);
    assertEq(lockdrop.totalP88Weight(), 11 ether * lockPeriod);

    vm.warp(lockdropConfig.startLockTimestamp() + 2 days);
    lockdrop.earlyWithdrawLockedToken(11 ether, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw all of her ERC20 token within the first 3 days, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 20
    // 2. Alice is now deleted from lockdropStates so her lock token amount is 0
    // 3. Alice is now deleted from lockdropStates so her lock period is 0
    assertEq(mockERC20.balanceOf(ALICE), 20 ether);
    assertEq(alicelockdropTokenAmount, 0);
    assertEq(alicelockPeriod, 0);
    vm.stopPrank();
  }

  function testCorrectness_LockdropEarlyWithdrawLockToken_WithdrawDay4First12Hours()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(lockAmount, lockPeriod);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 3 days + 2 hours);
    assertEq(lockdrop.getEarlyWithdrawableAmount(ALICE), 8 ether);
    lockdrop.earlyWithdrawLockedToken(5 ether, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw the ERC20 token on day 4 in the first 12 hours, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 9
    // 2. The amount of Alice's lockdrop token should be 11
    // 3. The number of lock period should be 8 days
    // 4. The total amount of lock token should be 11
    // 5. The total weight of P88 should be 11 * 8 days
    assertEq(mockERC20.balanceOf(ALICE), 9 ether);
    assertEq(alicelockdropTokenAmount, 11 ether);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), 11 ether);
    assertEq(lockdrop.totalP88Weight(), 11 ether * lockPeriod);
  }

  function testCorrectness_LockdropEarlyWithdrawLockToken_WithdrawDay4Last12Hours()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    // Withdraw timestamp: Day 4 after 12 hours
    vm.warp(lockdropConfig.startLockTimestamp() + 3 days + 18 hours);
    assertEq(lockdrop.getEarlyWithdrawableAmount(ALICE), 4 ether);
    lockdrop.earlyWithdrawLockedToken(4 ether, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    // After Alice withdraw the ERC20 token on day 4 in the last 12 hours, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 8
    // 2. The amount of Alice's lockdrop token should be 12
    // 3. Alice hasn't claim her P88 so should be false
    // 4. The number of lock period should be 8 days
    // 5. The total amount of lock token should be 12
    // 6. The total weight of P88 should be `1 * 8 days
    assertEq(mockERC20.balanceOf(ALICE), 8 ether);
    assertEq(alicelockdropTokenAmount, 12 ether);
    assertEq(alicelockPeriod, lockPeriod);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 12 ether);
    assertEq(lockdrop.totalP88Weight(), 12 ether * lockPeriod);
  }

  function testRevert_LockdropEarlyWithdrawLockToken_ExceedLockdropPeriod()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    vm.warp(lockdropConfig.startLockTimestamp() + 4 days + 1 hours);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotInLockdropPeriod()"));
    lockdrop.earlyWithdrawLockedToken(5 ether, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawDay4First12HoursInvalidAmount()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);

    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    // Withdraw timestamp
    vm.warp(lockdropConfig.startLockTimestamp() + 3 days + 2 hours);
    // Withdraw more than 50%
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidAmount()"));
    lockdrop.earlyWithdrawLockedToken(10 ether, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawDay4Last12HoursInvalidAmount()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);

    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertTrue(!aliceP88Claimed);

    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    // Withdraw timestamp: Day 4 after 12 hours
    vm.warp(lockdropConfig.startLockTimestamp() + 3 days + 18 hours);
    // Withdraw more than valid amount
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidAmount()"));
    lockdrop.earlyWithdrawLockedToken(5 ether, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawAmountIsZero()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);

    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    vm.warp(lockdropConfig.startLockTimestamp() + 2 days);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_ZeroAmountNotAllowed()"));
    lockdrop.earlyWithdrawLockedToken(0, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawAmountExceedLockAmount()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);

    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    vm.warp(lockdropConfig.startLockTimestamp() + 2 days);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InsufficientBalance()"));
    lockdrop.earlyWithdrawLockedToken(20 ether, ALICE);
    vm.stopPrank();
  }

  // ------ withdrawAll ------
  function testCorrectness_LockdropWithdrawAll() external {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);
    vm.stopPrank();

    vm.warp(lockdropConfig.endLockTimestamp() + lockPeriod);

    vm.startPrank(address(this));
    // Owner mint PLPToken
    mockPLPToken.mint(address(lockdrop), 20 ether);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 100 ether);

    lockdrop.stakePLP();
    assertEq(mockPLPToken.balanceOf(address(lockdrop)), 19999999999999999980);
    vm.stopPrank();

    vm.startPrank(ALICE);
    lockdrop.withdrawAll(ALICE);
    (alicelockdropTokenAmount, alicelockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();

    // After Alice withdrawAll, the following criteria needs to satisfy:
    // 1. Balance of Alice's PLP token should be 20
    // 2. Balance of lockdrop PLP token should be 19999999999999999980
    // 3. Since Alice is the only one who lock the token, the total amount of PLP token in the contract should remain the same
    // 4. Alice is now deleted from lockdropStates so her lock token amount is 0
    // 5. Alice is now deleted from lockdropStates so her lock period is 0
    assertEq(mockPLPToken.balanceOf(ALICE), 20);
    assertEq(mockPLPToken.balanceOf(address(lockdrop)), 19999999999999999980);
    assertEq(lockdrop.totalPLPAmount(), 20);

    assertEq(alicelockdropTokenAmount, 0);
    assertEq(alicelockPeriod, 0);
  }

  function testRevert_LockdropWithdrawAll_WithdrawAllBeforeEndOfLockdropHaveZeroPLP()
    external
  {
    uint256 lockAmount = 16 ether;
    uint256 lockPeriod = 8 days;

    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(lockAmount, lockPeriod);
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, lockAmount);
    assertEq(alicelockPeriod, lockPeriod);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), lockAmount);
    assertEq(lockdrop.totalP88Weight(), lockAmount * lockPeriod);

    vm.expectRevert(abi.encodeWithSignature("Lockdrop_ZeroTotalPLPAmount()"));
    lockdrop.withdrawAll(ALICE);
  }
}
