// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../base/DSTest.sol";
import { console } from "../utils/console.sol";
import { BaseTest } from "../base/BaseTest.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error LockDrop_NotInDepositPeriod();

contract LockdropTest is BaseTest {
  Lockdrop internal lockdrop;
  MockErc20 internal mockERC20;

  function setUp() external {
    mockERC20 = new MockErc20("Mock Token", "MT", 18);
    lockdrop = new Lockdrop(address(mockERC20), 100000);
  }

  function test_LockdropIsInit_ShouldBeCorrectlyInit() external {
    assertEq(lockdrop.lockdropToken.address, address(mockERC20));
    assertEq(lockdrop.startLockTimestamp, 100000);
    assertEq(lockdrop.endLockTimestamp, 704800);
    assertEq(lockdrop.withdrawalTimestamp, 532000);
  }

  function test_LockdropLockToken_ShouldWorkCorrectly() external {
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

  function test_LockdropLockToken_InWithdrawPeriod() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(532500);
    vm.expectRevert(LockDrop_NotInDepositPeriod.selector);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
  }

  function test_LockdropLockToken_ExceedDepositAndWithdrawPeriod() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(535000);
    vm.expectRevert(LockDrop_NotInDepositPeriod.selector);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
  }
}
