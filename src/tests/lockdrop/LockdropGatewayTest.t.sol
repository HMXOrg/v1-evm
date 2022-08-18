// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { LockdropGateway } from "../../lockdrop/LockdropGateway.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { console } from "../utils/console.sol";
import { MockLockdrop } from "../mocks/MockLockdrop.sol";
import { ILockdrop } from "../../lockdrop/interfaces/ILockdrop.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockdropGatewayTest is BaseTest {
  LockdropGateway internal lockdropGateway;
  MockErc20 internal baseToken;
  MockLockdrop internal lockdrop;
  address[] internal lockdropList;
  MockErc20 internal p88;

  function setUp() external {
    baseToken = new MockErc20("Etherium", "ETH", 18);
    lockdropGateway = new LockdropGateway();
    lockdrop = new MockLockdrop();
  }

  function testCorrectness_WhenUserLockToken_ThenClaimAllReward() external {
    baseToken.mint(address(this), 10 ether);
    baseToken.approve(address(lockdrop), 10 ether);

    // User Locked their tokens
    lockdrop.lockToken(
      address(baseToken),
      IERC20(baseToken).balanceOf(address(this)),
      10000
    );
    lockdropList.push(address(lockdrop));

    // Expect the tokens have been locked;
    assertEq(IERC20(baseToken).balanceOf(address(this)), 0 ether);

    // User claim their P88 reward
    lockdropGateway.claimAllReward(lockdropList, address(this));

    // Expect the user get their reward
    assertEq(
      IERC20(lockdrop.getP88Address()).balanceOf(address(this)),
      20 ether
    );
  }

  function testCorrectness_WhenUserLockToken_ThenUserWithDrawAllLockToken()
    external
  {
    baseToken.mint(address(this), 10 ether);
    baseToken.approve(address(lockdrop), 10 ether);

    assertEq(IERC20(baseToken).balanceOf(address(this)), 10 ether);

    // User Locked their tokens
    lockdrop.lockToken(
      address(baseToken),
      IERC20(baseToken).balanceOf(address(this)),
      10000
    );
    lockdropList.push(address(lockdrop));

    // Expect the tokens have been locked;
    assertEq(IERC20(baseToken).balanceOf(address(this)), 0 ether);

    // User need to withdraw all locked tokens
    lockdropGateway.withdrawLockedToken(10 ether, lockdropList, address(this));

    // Expect user got return their locked token
    assertEq(IERC20(baseToken).balanceOf(address(this)), 10 ether);
  }

  function testCorectness_WhenUserLockToken_ThenUserWithDrawSomeLockToken()
    external
  {
    baseToken.mint(address(this), 10 ether);
    baseToken.approve(address(lockdrop), 10 ether);

    assertEq(IERC20(baseToken).balanceOf(address(this)), 10 ether);

    // User Locked their tokens
    lockdrop.lockToken(
      address(baseToken),
      IERC20(baseToken).balanceOf(address(this)),
      10000
    );
    lockdropList.push(address(lockdrop));

    // Expect the tokens have been locked;
    assertEq(IERC20(baseToken).balanceOf(address(this)), 0 ether);

    // User need to withdraw some of locked tokens
    lockdropGateway.withdrawLockedToken(5 ether, lockdropList, address(this));

    // Expect user got return their locked token
    assertEq(IERC20(baseToken).balanceOf(address(this)), 5 ether);
  }

  function testRevert_WhenUserHaveNoLockedToken_ThenUserCannotClaimAllReward()
    external
  {
    assertEq(IERC20(baseToken).balanceOf(address(this)), 0 ether);
    lockdropList.push(address(lockdrop));

    //  Expect Revert
    vm.expectRevert();
    lockdropGateway.claimAllReward(lockdropList, address(this));
  }

  function testRevert_WhenUserHaveNoLockedToken_ThenUserCannotWithdrawToken()
    external
  {
    assertEq(IERC20(baseToken).balanceOf(address(this)), 0 ether);
    lockdropList.push(address(lockdrop));

    //  Expect Revert
    vm.expectRevert();
    lockdropGateway.withdrawLockedToken(5 ether, lockdropList, address(this));
  }
}
