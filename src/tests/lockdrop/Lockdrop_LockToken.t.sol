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
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();
    // After Alice lock the ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alices' ERC20 token should be 4
    // 2. The amount of Alices' lockdrop token should be 16
    // 3. The number of lock period should be 604900
    // 4. The total amount of lock token should be 16
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);

    // ------- Bob session -------
    vm.startPrank(BOB, BOB);
    mockERC20.mint(BOB, 30);
    mockERC20.approve(address(lockdrop), 30);
    vm.warp(130000);
    lockdrop.lockToken(address(mockERC20), 10, 704900);
    (uint256 bobLockdropTokenAmount, uint256 bobLockPeriod) = lockdrop
      .lockdropStates(BOB);
    vm.stopPrank();
    // After Bob lock the ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Bobs' ERC20 token should be 20
    // 2. The amount of Bobs' lockdrop token should be 10
    // 3. The number of lock period should be 704900
    // 4. The total amount of lock token should be 16 + 10 = 26
    assertEq(mockERC20.balanceOf(BOB), 20);
    assertEq(bobLockdropTokenAmount, 10);
    assertEq(bobLockPeriod, 704900);
    assertEq(lockdrop.totalAmount(), 26);
  }

  function testRevert_LockdropLockToken_InWithdrawPeriod() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(532500);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotInDepositPeriod()"));
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_ExceedLockdropPeriod()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(705000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotInDepositPeriod()"));
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_DepositeZeroToken() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(130000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_ZeroAmountNotAllowed()"));
    lockdrop.lockToken(address(mockERC20), 0, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_LockPeriodLessThan7Days() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(130000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidLockPeriod()"));
    lockdrop.lockToken(address(mockERC20), 16, 1);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_LockPeriodMoreThan364Days() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(130000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidLockPeriod()"));
    lockdrop.lockToken(address(mockERC20), 16, 31622400);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_MismatchToken() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(130000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_MismatchToken()"));
    lockdrop.lockToken(address(mock2ERC20), 16, 604900);
    vm.stopPrank();
  }
}
