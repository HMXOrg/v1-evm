// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_ClaimAllReward is Lockdrop_BaseTest {
  function setUp() public override {
    super.setUp();
    mockP88Token.setMinter(address(lockdrop), true);
  }

  function testCorrectness_AllocateP88_OnlyOneUser() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // After lockdrop period
    // Mint P88
    vm.warp(705000);
    vm.startPrank(address(lockdrop), address(lockdrop));
    mockP88Token.mint(address(lockdrop), 100);
    mockP88Token.approve(address(lockdrop), 100);
    lockdrop.allocateP88(100);
    vm.stopPrank();

    vm.startPrank(ALICE, ALICE);
    lockdrop.claimAllP88(ALICE);
    vm.stopPrank();
    // After claims her P88, the following criteria needs to satisfy:
    // 1. The amount of Alice's P88 should be 100
    // 2. The amount of lockdrop P88 should be 0
    // 3. Status of Alice claiming P88 should be true
    assertEq(mockP88Token.balanceOf(ALICE), 100);
    assertEq(mockP88Token.balanceOf(address(lockdrop)), 0);
    assertTrue(lockdrop.claimP88(ALICE));

  }

  function testCorrectness_AllocateP88_MultipleUser() external {
    // ------- Alice session -------
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);
    assertTrue(!lockdrop.claimP88(ALICE));

    // ------- Bob session -------
    vm.startPrank(BOB, BOB);
    mockERC20.mint(BOB, 30);
    mockERC20.approve(address(lockdrop), 30);
    vm.warp(130000);
    lockdrop.lockToken(10, 704900);
    (uint256 bobLockdropTokenAmount, uint256 bobLockPeriod) = lockdrop
      .lockdropStates(BOB);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(BOB), 20);
    assertEq(bobLockdropTokenAmount, 10);
    assertEq(bobLockPeriod, 704900);
    assertEq(lockdrop.totalAmount(), 26);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900 + 10 * 704900);
    assertTrue(!lockdrop.claimP88(BOB));

    // After lockdrop period
    // Mint P88
    vm.warp(705000);
    vm.startPrank(address(lockdrop), address(lockdrop));
    mockP88Token.mint(address(lockdrop), 100);
    mockP88Token.approve(address(lockdrop), 100);
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

    // After claims her P88, the following criteria needs to satisfy:
    // 1. The amount of Alice's P88 should be 57
    // 2. The amount of Bob's P88 should be 42
    // 3. The amount of lockdrop P88 should be 1
    // 4. Status of Alice claiming P88 should be true
    // 5. Status of Bob claiming P88 should be true
    assertEq(mockP88Token.balanceOf(ALICE), 57);
    assertEq(mockP88Token.balanceOf(BOB), 42);
    assertEq(mockP88Token.balanceOf(address(lockdrop)), 1);
    assertTrue(lockdrop.claimP88(ALICE));
    assertTrue(lockdrop.claimP88(BOB));

  }
}
