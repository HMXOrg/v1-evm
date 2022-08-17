// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_LockToken is Lockdrop_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_LockdropLockToken() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
    (uint256 lockdropTokenAmount, uint256 lockPeriod) = lockdrop.lockdropStates(
      ALICE
    );
    assertEq(lockdropTokenAmount, 16);
    assertEq(lockPeriod, 604900);
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

  function testRevert_LockdropLockToken_ExceedDepositAndWithdrawPeriod()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(535000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotInDepositPeriod()"));
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
  }
}
