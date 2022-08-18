// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_WithdrawLockToken is Lockdrop_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_LockdropWithdrawLockToken() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);

    // Withdraw timestamp
    vm.warp(533000);
    lockdrop.withdrawLockToken(5, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw the ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alices' ERC20 token should be 9
    // 2. The amount of Alices' lockdrop token should be 11
    // 3. The number of lock period should be 604900
    // 4. The total amount of lock token should be 11
    assertEq(mockERC20.balanceOf(ALICE), 9);
    assertEq(alicelockdropTokenAmount, 11);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 11);

    vm.warp(553000);
    lockdrop.withdrawLockToken(11, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw all of her ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alices' ERC20 token should be 20
    // 2. Alice is now deleted from lockdropStates so her lock token amount is 0
    // 3. Alice is now deleted from lockdropStates so her lock period is 0
    assertEq(mockERC20.balanceOf(ALICE), 20);
    assertEq(alicelockdropTokenAmount, 0);
    assertEq(alicelockPeriod, 0);
    vm.stopPrank();
  }

  function testRevert_LockdropWithdrawLockToken_BeforeWithdrawPeriod()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);

    vm.warp(130000);
    vm.expectRevert(
      abi.encodeWithSignature("Lockdrop_NotInWithdrawalPeriod()")
    );
    lockdrop.withdrawLockToken(5, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropWithdrawLockToken_ExceedLockdropPeriod()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);

    vm.warp(705000);
    console.log(lockdropConfig.endLockTimestamp());
    vm.expectRevert(
      abi.encodeWithSignature("Lockdrop_NotInWithdrawalPeriod()")
    );
    lockdrop.withdrawLockToken(5, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropWithdrawLockToken_WithdrawAmountIsZero()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);

    vm.warp(533000);
    console.log(lockdropConfig.endLockTimestamp());
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_ZeroAmountNotAllowed()"));
    lockdrop.withdrawLockToken(0, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropWithdrawLockToken_WithdrawAmountExceedLockAmount()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);

    vm.warp(533000);
    console.log(lockdropConfig.endLockTimestamp());
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InsufficientBalance()"));
    lockdrop.withdrawLockToken(20, ALICE);
    vm.stopPrank();
  }
}
