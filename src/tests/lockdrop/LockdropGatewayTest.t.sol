// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { LockdropGateway } from "../../lockdrop/LockdropGateway.sol";
import { MockLockdropConfig } from "../mocks/MockLockdropConfig.sol";
import { PLPStaking } from "../../staking/PLPStaking.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { console } from "../utils/console.sol";
import { MockLockdrop } from "../mocks/MockLockdrop.sol";
import { ILockdrop } from "../../lockdrop/interfaces/ILockdrop.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockdropGatewayTest is BaseTest {
  LockdropGateway internal lockdropGateway;
  MockLockdropConfig internal lockdropConfig;
  PLPStaking internal plpStaking;
  MockErc20 internal lockdropToken;
  MockLockdrop internal lockdrop;
  address[] internal lockdropList;
  MockErc20 internal p88;
  MockErc20 internal plp;

  function setUp() external {
    lockdropToken = new MockErc20("LockdropToken", "LCKT", 18);
    lockdropToken.mint(address(this), 10 ether);

    p88 = new MockErc20("P88", "P88", 18);
    plp = new MockErc20("PLP", "PLP", 18);
    plpStaking = new PLPStaking();

    lockdropConfig = new MockLockdropConfig(100000, plpStaking, plp, p88);

    lockdropGateway = deployLockdropGateway();
    lockdrop = new MockLockdrop(address(lockdropToken), lockdropConfig);

    lockdropToken.approve(address(lockdrop), 10 ether);
    lockdrop.lockToken(IERC20(lockdropToken).balanceOf(address(this)), 604900);
    lockdropList.push(address(lockdrop));
  }

  function testCorrectness_WhenUserLockToken_ThenClaimAllP88Reward() external {
    // Expect the tokens have been locked;
    assertEq(IERC20(lockdropToken).balanceOf(address(this)), 0 ether);
    assertEq(IERC20(lockdropToken).balanceOf(address(lockdrop)), 10 ether);

    // User claim their P88 reward
    lockdropGateway.claimAllP88(lockdropList, address(this));

    // Expect the user get their reward
    assertEq(IERC20(p88).balanceOf(address(this)), 10 ether);
  }

  function testCorrectness_WhenUserLockToken_ThenUserWithdrawAllLockToken()
    external
  {
    // Expect the tokens have been locked;
    assertEq(IERC20(lockdropToken).balanceOf(address(this)), 0 ether);
    assertEq(IERC20(lockdropToken).balanceOf(address(lockdrop)), 10 ether);

    // User need to withdraw all locked tokens
    lockdropGateway.withdrawAllLockedToken(lockdropList, address(this));

    // Expect user got return their locked token
    assertEq(IERC20(lockdropToken).balanceOf(address(this)), 10 ether);
  }

  function testCorrectness_WhenUserLockToken_ThenUserClaimAllReward() external {
    // Expect the tokens have been locked;
    assertEq(IERC20(lockdropToken).balanceOf(address(this)), 0 ether);
    assertEq(IERC20(lockdropToken).balanceOf(address(lockdrop)), 10 ether);

    // User claim their All reward
    lockdropGateway.claimAllStakingContractRewards(lockdropList, address(this));

    // Expect the user get their reward
    assertEq(IERC20(p88).balanceOf(address(this)), 10 ether);
    assertEq(IERC20(plp).balanceOf(address(this)), 10 ether);
  }
}
