// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../base/DSTest.sol";
import { console } from "../utils/console.sol";
import { BaseTest } from "../base/BaseTest.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { MockERC20 } from "../mock/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockdropTest is BaseTest {
    Lockdrop internal lockdrop;
    MockERC20 internal mockERC20;

    function setUp() external {
        mockERC20 = new MockERC20("Mock Token", "MT");
        lockdrop = new Lockdrop(address(mockERC20), 100000);
    }

    function test_LockdropIsInit_ShouldBeCorrectlyInit() external {
        (IERC20 lockdropToken, uint startLockTimestamp, uint endLockTimestamp, uint withdrawalTimestamp)= lockdrop.lockdropConfig();
        assertEq(address(lockdropToken), address(mockERC20));
        assertEq(startLockTimestamp, 100000);
        assertEq(endLockTimestamp, 704800);
        assertEq(withdrawalTimestamp, 532000);
    }

    function test_LockdropLockToken_ShouldWorkCorrectly() external {
        (IERC20 lockdropToken, uint startLockTimestamp, uint endLockTimestamp, uint withdrawalTimestamp)= lockdrop.lockdropConfig();
        vm.startPrank(ALICE, ALICE);
        mockERC20.mint(ALICE, 20);
        mockERC20.approve(address(lockdrop), 20);
        lockdrop.lockToken(address(mockERC20), 16, 604900);
        vm.stopPrank();
        (uint256 lockdropTokenAmount, uint256 lockPeriod) = lockdrop.LockdropStates(ALICE);
        assertEq(lockdropTokenAmount, 16);
        assertEq(lockPeriod, 604900);
    }
}