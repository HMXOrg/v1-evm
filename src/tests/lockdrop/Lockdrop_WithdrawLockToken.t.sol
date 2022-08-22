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
  function testCorrectness_LockdropEarlyWithdrawLockToken() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Withdraw timestamp
    vm.warp(533000);
    lockdrop.earlyWithdrawLockedToken(5, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw the ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 9
    // 2. The amount of Alice's lockdrop token should be 11
    // 3. The number of lock period should be 604900
    // 4. The total amount of lock token should be 11
    assertEq(mockERC20.balanceOf(ALICE), 9);
    assertEq(alicelockdropTokenAmount, 11);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 11);
    assertEq(lockdrop.totalP88Weight(), 11 * 604900);

    vm.warp(553000);
    lockdrop.earlyWithdrawLockedToken(11, ALICE);
    (alicelockdropTokenAmount, alicelockPeriod) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw all of her ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 20
    // 2. Alice is now deleted from lockdropStates so her lock token amount is 0
    // 3. Alice is now deleted from lockdropStates so her lock period is 0
    assertEq(mockERC20.balanceOf(ALICE), 20);
    assertEq(alicelockdropTokenAmount, 0);
    assertEq(alicelockPeriod, 0);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_BeforeWithdrawPeriod()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.warp(130000);
    vm.expectRevert(
      abi.encodeWithSignature("Lockdrop_NotInWithdrawalPeriod()")
    );
    lockdrop.earlyWithdrawLockedToken(5, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_ExceedLockdropPeriod()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.warp(705000);
    vm.expectRevert(
      abi.encodeWithSignature("Lockdrop_NotInWithdrawalPeriod()")
    );
    lockdrop.earlyWithdrawLockedToken(5, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropEarlyWithdrawLockToken_WithdrawAmountIsZero()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.warp(533000);
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
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.warp(533000);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InsufficientBalance()"));
    lockdrop.earlyWithdrawLockedToken(20, ALICE);
    vm.stopPrank();
  }

  // ------ withdrawAll ------
  function testCorrectness_LockdropWithdrawAll() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);
    vm.stopPrank();

    vm.warp(704800 + 605000);
    vm.startPrank(address(lockdrop), address(lockdrop));
    mockPLPToken.mint(address(lockdrop), 20);
    mockERC20.approve(address(strategy), 100);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 20);
    lockdrop.stakePLP();
    vm.stopPrank();

    vm.startPrank(ALICE, ALICE);
    lockdrop.withdrawAll(ALICE);
    (alicelockdropTokenAmount, alicelockPeriod) = lockdrop.lockdropStates(
      ALICE
    );
    vm.stopPrank();

    // After Alice withdrawAll, the following criteria needs to satisfy:
    // 1. Balance of Alice's PLP token should be 20
    // 2. Balance of lockdrop PLP token should be 0
    // 3. Since Alice is the only one who lock the token, the total amount of PLP token in the contract should be 0
    // 4. Alice is now deleted from lockdropStates so her lock token amount is 0
    // 5. Alice is now deleted from lockdropStates so her lock period is 0
    assertEq(mockPLPToken.balanceOf(ALICE), 20);
    assertEq(mockPLPToken.balanceOf(address(lockdrop)), 0);
    assertEq(lockdrop.totalPLPAmount(), 0);
    assertEq(alicelockdropTokenAmount, 0);
    assertEq(alicelockPeriod, 0);
  }

  function testRevert_LockdropWithdrawAll_WithdrawAllBeforeEndOfLockdrop()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    vm.expectRevert(
      abi.encodeWithSignature("Lockdrop_InvalidWithdrawPeriod()")
    );
    lockdrop.withdrawAll(ALICE);
  }
}
