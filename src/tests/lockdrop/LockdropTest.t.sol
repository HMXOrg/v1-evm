// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../base/DSTest.sol";
import { console } from "../utils/console.sol";
import { BaseTest } from "../base/BaseTest.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockPool } from "../mocks/MockPool.sol";
import { SimpleStrategy } from "../../lockdrop/SimpleStrategy.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LockdropTest is BaseTest {
  using SafeERC20 for IERC20;

  Lockdrop internal lockdrop;
  MockErc20 internal mockERC20;
  MockPool internal pool;
  SimpleStrategy internal strategy;

  function setUp() external {
    pool = new MockPool();
    strategy = new SimpleStrategy(pool);
    mockERC20 = new MockErc20("Mock Token", "MT", 18);
    lockdrop = new Lockdrop(address(mockERC20), 100000, strategy);
  }

  function testCorrectness_WhenLockdropIsInit() external {
    assertEq(address(lockdrop.lockdropToken()), address(mockERC20));
    assertEq(lockdrop.startLockTimestamp(), uint256(100000));
    assertEq(lockdrop.endLockTimestamp(), uint256(704800));
    assertEq(lockdrop.withdrawalTimestamp(), uint256(532000));
  }

  function testCorrectness_LockdropLockToken() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
    (uint256 lockdropTokenAmount, uint256 lockPeriod) = lockdrop.LockdropStates(
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
    vm.expectRevert(abi.encodeWithSignature("LockDrop_NotInDepositPeriod()"));
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_ExceedDepositAndWithdrawPeriod() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(535000);
    vm.expectRevert(abi.encodeWithSignature("LockDrop_NotInDepositPeriod()"));
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
  }

  function testCorrectness_LockdropMintPLP_SuccessfullyGetPLPAmount() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
    (uint256 lockdropTokenAmountAlice, uint256 lockPeriodAlice) = lockdrop
      .LockdropStates(ALICE);
    assertEq(lockdropTokenAmountAlice, 16);
    assertEq(lockPeriodAlice, 604900);
    assertEq(mockERC20.balanceOf(ALICE), 4);

    vm.startPrank(BOB, BOB);
    mockERC20.mint(BOB, 30);
    mockERC20.approve(address(lockdrop), 30);

    vm.warp(130000);
    lockdrop.lockToken(address(mockERC20), 29, 605000);
    vm.stopPrank();
    (uint256 lockdropTokenAmountBob, uint256 lockPeriodBob) = lockdrop
      .LockdropStates(BOB);
    assertEq(lockdropTokenAmountBob, 29);
    assertEq(lockPeriodBob, 605000);
    assertEq(mockERC20.balanceOf(BOB), 1);

    vm.startPrank(address(lockdrop), address(lockdrop));
    mockERC20.approve(address(strategy), 45);
    lockdrop.mintPLP();
    assertEq(mockERC20.balanceOf(address(lockdrop)), 0);
    assertEq(mockERC20.balanceOf(address(strategy)), 45);
    assertEq(lockdrop.plpAmount(), 20);
    vm.stopPrank();
  }
}
