// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_ClaimReward is Lockdrop_BaseTest {
  function setUp() public override {
    super.setUp();
    mockP88Token.setMinter(address(this), true);
  }

  // -------------------- claimAllP88 ----------------------------
  function testCorrectness_ClaimAllP88_OnlyOneUser() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (
      uint256 aliceLockdropTokenAmount,
      uint256 aliceLockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // After lockdrop period
    // Mint P88
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);
    vm.startPrank(address(this), address(this));
    mockP88Token.mint(address(this), 100);
    mockP88Token.approve(address(lockdrop), 1000);
    lockdrop.allocateP88(100);
    vm.stopPrank();

    vm.startPrank(ALICE, ALICE);
    lockdrop.claimAllP88(ALICE);
    vm.stopPrank();

    (aliceLockdropTokenAmount, aliceLockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);

    // After Alice claims her P88, the following criteria needs to satisfy:
    // 1. The amount of Alice's P88 should be 100
    // 2. The amount of lockdrop P88 should be 0
    // 3. Status of Alice claiming P88 should be true
    assertEq(mockP88Token.balanceOf(ALICE), 100);
    assertEq(mockP88Token.balanceOf(address(lockdrop)), 0);
    assertTrue(aliceP88Claimed);
  }

  function testCorrectness_ClaimAllP88_MultipleUser() external {
    // ------- Alice session -------
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (
      uint256 aliceLockdropTokenAmount,
      uint256 aliceLockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);
    assertTrue(!aliceP88Claimed);

    // ------- Bob session -------
    vm.startPrank(BOB, BOB);
    mockERC20.mint(BOB, 30);
    mockERC20.approve(address(lockdrop), 30);
    vm.warp(130000);
    lockdrop.lockToken(10, 704900);
    (
      uint256 bobLockdropTokenAmount,
      uint256 bobLockPeriod,
      bool bobP88Claimed
    ) = lockdrop.lockdropStates(BOB);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(BOB), 20);
    assertEq(bobLockdropTokenAmount, 10);
    assertEq(bobLockPeriod, 704900);
    assertEq(lockdrop.totalAmount(), 26);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900 + 10 * 704900);
    assertTrue(!bobP88Claimed);

    // After lockdrop period
    // Mint P88
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);
    vm.startPrank(address(this), address(this));
    mockP88Token.mint(address(this), 100);
    mockP88Token.approve(address(lockdrop), 1000);
    lockdrop.allocateP88(100);
    vm.stopPrank();

    // Alice claims her P88
    vm.startPrank(ALICE, ALICE);
    lockdrop.claimAllP88(ALICE);
    vm.stopPrank();

    // Bob claims his P88
    vm.startPrank(BOB, BOB);
    lockdrop.claimAllP88(BOB);
    vm.stopPrank();

    (bobLockdropTokenAmount, bobLockPeriod, bobP88Claimed) = lockdrop
      .lockdropStates(BOB);
    (aliceLockdropTokenAmount, aliceLockPeriod, aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);

    // After claims her P88, the following criteria needs to satisfy:
    // 1. The amount of Alice's P88 should be 57
    // 2. The amount of Bob's P88 should be 42
    // 3. The amount of lockdrop P88 should be 1
    // 4. Status of Alice claiming P88 should be true
    // 5. Status of Bob claiming P88 should be true
    assertEq(mockP88Token.balanceOf(ALICE), 57);
    assertEq(mockP88Token.balanceOf(BOB), 42);
    assertEq(mockP88Token.balanceOf(address(lockdrop)), 1);
    assertTrue(aliceP88Claimed);
    assertTrue(bobP88Claimed);
  }

  function testRevert_ClaimAllP88_TotalP88NotSet() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (
      uint256 aliceLockdropTokenAmount,
      uint256 aliceLockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // After lockdrop period
    // Mint P88
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);

    vm.startPrank(address(this), address(this));
    mockP88Token.mint(address(this), 100);
    mockP88Token.approve(address(lockdrop), 1000);
    vm.stopPrank();

    vm.startPrank(ALICE, ALICE);
    // Haven't call allocateP88
    vm.expectRevert(
      abi.encodeWithSignature("Lockdrop_ZeroTotalP88NotAllowed()")
    );
    lockdrop.claimAllP88(ALICE);
    vm.stopPrank();
  }

  function testRevert_ClaimAllP88_AlreadyClaimedReward() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (
      uint256 aliceLockdropTokenAmount,
      uint256 aliceLockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertTrue(!aliceP88Claimed);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // After lockdrop period
    // Mint P88
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);

    vm.startPrank(address(this), address(this));
    mockP88Token.mint(address(this), 100);
    mockP88Token.approve(address(lockdrop), 1000);
    lockdrop.allocateP88(100);
    vm.stopPrank();

    vm.startPrank(ALICE, ALICE);
    lockdrop.claimAllP88(ALICE);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_P88AlreadyClaimed()"));
    lockdrop.claimAllP88(ALICE);
    vm.stopPrank();
  }
}
