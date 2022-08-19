// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console, MockErc20 } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_LockToken is Lockdrop_BaseTest {
  MockErc20 internal mock2ERC20;

  function setUp() public override {
    super.setUp();
    mock2ERC20 = new MockErc20("Mock Token2", "MT2", 18);
  }

  function testCorrectness_LockdropLockToken() external {
    // ------- Alice session -------
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();
    // After Alice lock the ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 4
    // 2. The amount of Alice's lockdrop token should be 16
    // 3. The number of lock period should be 604900
    // 4. The total amount of lock token should be 16
    // 5. The total P88 weight should be 16 * 604900
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // ------- Bob session -------
    vm.startPrank(BOB, BOB);
    mockERC20.mint(BOB, 30);
    mockERC20.approve(address(lockdrop), 30);
    vm.warp(130000);
    lockdrop.lockToken(10, 704900);
    (uint256 bobLockdropTokenAmount, uint256 bobLockPeriod) = lockdrop
      .lockdropStates(BOB);
    vm.stopPrank();
    // After Bob lock the ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Bobs' ERC20 token should be 20
    // 2. The amount of Bobs' lockdrop token should be 10
    // 3. The number of lock period should be 704900
    // 4. The total amount of lock token should be 16 + 10 = 26
    // 5. The total P88 weight should be 16 * 604900 + 10 * 704900
    assertEq(mockERC20.balanceOf(BOB), 20);
    assertEq(bobLockdropTokenAmount, 10);
    assertEq(bobLockPeriod, 704900);
    assertEq(lockdrop.totalAmount(), 26);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900 + 10 * 704900);
  }

  function testCorrectness_LockdropAddLockAmount() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Alice wants to lock more
    lockdrop.addLockAmount(4);
    vm.stopPrank();

    (aliceLockdropTokenAmount, aliceLockPeriod) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice add more ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 0
    // 2. The amount of Alice's lockdrop token should be 20
    // 3. The number of lock period should be 604900
    // 4. The total amount of lock token should be 20
    // 5. The total P88 weight should be 20 * 604900
    assertEq(mockERC20.balanceOf(ALICE), 0);
    assertEq(aliceLockdropTokenAmount, 20);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 20);
    assertEq(lockdrop.totalP88Weight(), 20 * 604900);
  }

  function testRevert_LockdropLockToken_InWithdrawPeriod() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(532500);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotInDepositPeriod()"));
    lockdrop.lockToken(16, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_ExceedLockdropPeriod() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(705000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotInDepositPeriod()"));
    lockdrop.lockToken(16, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_DepositZeroToken() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(130000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_ZeroAmountNotAllowed()"));
    lockdrop.lockToken(0, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_LockPeriodLessThan7Days() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(130000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidLockPeriod()"));
    lockdrop.lockToken(16, 1);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_LockPeriodMoreThan364Days() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(130000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidLockPeriod()"));
    lockdrop.lockToken(16, 31622400);
    vm.stopPrank();
  }
}
