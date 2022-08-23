// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";
import { MockRewarder } from "../mocks/MockRewarder.sol";

contract Lockdrop_StakePLP is Lockdrop_BaseTest {
  MockRewarder internal PRRewarder;

  function setUp() public override {
    super.setUp();
    mockPLPToken.setMinter(address(lockdrop), true);
    PRRewarder = new MockRewarder();
    address[] memory rewarders1 = new address[](1);
    rewarders1[0] = address(PRRewarder);
    plpStaking.addStakingToken(address(mockPLPToken), rewarders1);
  }

  function testCorrectness_LockdropStakePLP_SuccessfullyGetPLPAmount()
    external
  {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    vm.stopPrank();
    (uint256 alicelockdropTokenAmount, uint256 alicelockPeriod, bool aliceP88Claimed) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(alicelockdropTokenAmount, 16);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);

    vm.startPrank(BOB, BOB);
    mockERC20.mint(BOB, 30);
    mockERC20.approve(address(lockdrop), 30);

    vm.warp(130000);
    lockdrop.lockToken(29, 605000);
    vm.stopPrank();
    (uint256 boblockdropTokenAmount, uint256 boblockPeriod, bool bobP88Claimed) = lockdrop
      .lockdropStates(BOB);
    assertEq(boblockdropTokenAmount, 29);
    assertEq(boblockPeriod, 605000);
    assertEq(mockERC20.balanceOf(BOB), 1);

    // After the lockdrop period ends, owner can stake PLP
    vm.startPrank(address(lockdrop), address(lockdrop));
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);
    mockERC20.approve(address(strategy), 45);
    mockPLPToken.mint(address(lockdrop), 20);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 20);
    lockdrop.stakePLP();
    assertEq(mockPLPToken.balanceOf(address(lockdrop)), 0);
    vm.stopPrank();
  }
}
