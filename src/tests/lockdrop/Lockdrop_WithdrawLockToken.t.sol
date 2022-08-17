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
    (uint256 AlicelockdropTokenAmount, uint256 AlicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(AlicelockdropTokenAmount, 16);
    assertEq(AlicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);

    vm.warp(533000);
    console.log(lockdropConfig.withdrawalTimestamp());
    lockdrop.withdrawLockToken(5, ALICE);
    (AlicelockdropTokenAmount, AlicelockPeriod) = lockdrop.lockdropStates(
      ALICE
    );
    assertEq(AlicelockdropTokenAmount, 11);
    assertEq(AlicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 11);
    assertEq(mockERC20.balanceOf(ALICE), 9);
    vm.stopPrank();
  }
}
