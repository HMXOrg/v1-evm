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
import { LockdropConfig } from "../../lockdrop/LockdropConfig.sol";
import { PLPStaking } from "../../staking/PLPStaking.sol";
import { MockRewarder } from "../mocks/MockRewarder.sol";

contract LockdropTest is BaseTest {
  using SafeERC20 for IERC20;

  Lockdrop internal lockdrop;
  MockErc20 internal mockERC20;
  MockErc20 internal mockPLPToken;
  MockPool internal pool;
  SimpleStrategy internal strategy;
  LockdropConfig internal lockdropConfig;
  PLPStaking internal plpStaking;

  MockRewarder internal PRRewarder;
  MockRewarder internal esP88Rewarder;
  MockRewarder internal PRewarder;

  function setUp() external {
    pool = new MockPool();
    strategy = new SimpleStrategy(pool);
    mockERC20 = new MockErc20("Mock Token", "MT", 18);
    mockPLPToken = new MockErc20("PLP", "PLP", 18);
     PRRewarder = new MockRewarder();
    esP88Rewarder = new MockRewarder();
    PRewarder = new MockRewarder();

    address[] memory rewarders1 = new address[](3);
    rewarders1[0] = address(PRRewarder);
    rewarders1[1] = address(esP88Rewarder);
    rewarders1[2] = address(PRewarder);
    plpStaking = new PLPStaking();
    plpStaking.addStakingToken(address(mockPLPToken), rewarders1);


    lockdropConfig = new LockdropConfig(
      100000,
      plpStaking,
      address(mockPLPToken)
    );
    lockdrop = new Lockdrop(address(mockERC20), strategy, lockdropConfig);
  }

  function testCorrectness_WhenLockdropIsInit() external {
    assertEq(address(lockdrop.lockdropToken()), address(mockERC20));
    assertEq(lockdropConfig.startLockTimestamp(), uint256(100000));
    assertEq(lockdropConfig.endLockTimestamp(), uint256(704800));
    assertEq(lockdropConfig.withdrawalTimestamp(), uint256(532000));
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

  function testCorrectness_LockdropMintPLP_SuccessfullyGetPLPAmount() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(address(mockERC20), 16, 604900);
    vm.stopPrank();
    (uint256 lockdropTokenAmountAlice, uint256 lockPeriodAlice) = lockdrop
      .lockdropStates(ALICE);
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
      .lockdropStates(BOB);
    assertEq(lockdropTokenAmountBob, 29);
    assertEq(lockPeriodBob, 605000);
    assertEq(mockERC20.balanceOf(BOB), 1);


    vm.startPrank(address(lockdrop), address(lockdrop));
    vm.warp(704900);
    mockERC20.approve(address(strategy), 45);
    mockPLPToken.mint(address(lockdrop), 20);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 20);
    lockdrop.stakePLP();
    assertEq(mockPLPToken.balanceOf(address(lockdrop)), 0);
    vm.stopPrank();
  }
}
