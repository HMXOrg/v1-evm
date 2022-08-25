// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_StakePLP is Lockdrop_BaseTest {
  function setUp() public override {
    super.setUp();
    mockPLPToken.setMinter(address(this), true);
  }

  function testCorrectness_LockdropStakePLP_SuccessfullyGetPLPAmount()
    external
  {
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    vm.stopPrank();
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(lockdrop.totalAmount(), 16);

    vm.startPrank(BOB);
    mockERC20.mint(BOB, 30);
    mockERC20.approve(address(lockdrop), 30);

    vm.warp(130000);
    lockdrop.lockToken(29, 605000);
    vm.stopPrank();
    (
      uint256 boblockdropTokenAmount,
      uint256 boblockPeriod,
      bool bobP88Claimed
    ) = lockdrop.lockdropStates(BOB);
    assertEq(mockERC20.balanceOf(BOB), 1);
    assertEq(boblockdropTokenAmount, 29);
    assertEq(lockdrop.totalAmount(), 45);

    // Lockdrop contract should have total amount of token that Alice and Bob locked
    assertEq(mockERC20.balanceOf(address(lockdrop)), 45);

    // After the lockdrop period ends, owner can stake PLP
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);

    // Lockdrop approve strategy and PLPStaking
    vm.startPrank(address(lockdrop));
    mockERC20.approve(address(strategy), 100);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 100);
    vm.stopPrank();

    vm.startPrank(address(this));
    // Owner mint PLPToken
    mockPLPToken.mint(address(lockdrop), 20);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 100);
    lockdrop.stakePLP();
    assertEq(mockPLPToken.balanceOf(address(lockdrop)), 0);
    vm.stopPrank();
  }

  function testRevert_LockdropStakePLP_MultipleStakingNotAllow() external {
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    vm.stopPrank();
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(lockdrop.totalAmount(), 16);

    // Lockdrop contract should have total amount of token that Alice and Bob locked
    assertEq(mockERC20.balanceOf(address(lockdrop)), 16);

    // After the lockdrop period ends, owner can stake PLP
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);

    // Lockdrop approve strategy and PLPStaking
    vm.startPrank(address(lockdrop));
    mockERC20.approve(address(strategy), 45);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 20);
    vm.stopPrank();

    vm.startPrank(address(this));
    // Owner mint PLPToken
    mockPLPToken.mint(address(lockdrop), 20);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 20);
    lockdrop.stakePLP();
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_PLPAlreadyStaked()"));
    lockdrop.stakePLP();
    vm.stopPrank();
  }
}
