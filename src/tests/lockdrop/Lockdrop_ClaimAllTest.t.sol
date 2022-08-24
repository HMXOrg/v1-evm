pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { BaseTest } from "../base/BaseTest.sol";
import { LockdropConfig } from "../../lockdrop/LockdropConfig.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { MockLockdropStrategy } from "../mocks/MockLockdropStrategy.sol";
import { MockPLPStaking } from "../mocks/MockPLPStaking.sol";

contract Lockdrop_ClaimReward is BaseTest {
  using SafeERC20 for IERC20;

  MockErc20 internal mockPLP;
  MockErc20 internal mockP88;
  MockErc20 internal mockEsP88;
  MockErc20 internal mockMatic;
  MockErc20 internal lockdropToken;
  address[] internal rewardsTokenList;
  LockdropConfig internal lockdropConfig;
  Lockdrop internal lockdrop;
  MockLockdropStrategy internal lockdropStrategy;
  MockPLPStaking internal mockPLPStaking;

  function setUp() external {
    lockdropStrategy = new MockLockdropStrategy();

    lockdropToken = new MockErc20("LockdropToken", "LCKT", 18);
    mockPLP = new MockErc20("PLP", "PLP", 18);
    mockP88 = new MockErc20("P88", "P88", 18);
    mockEsP88 = new MockErc20("EsP88", "EsP88", 18);
    mockMatic = new MockErc20("MATIC", "MATIC", 18);

    mockPLPStaking = new MockPLPStaking(
      address(mockPLP),
      address(mockMatic),
      address(mockEsP88)
    );

    lockdropConfig = new LockdropConfig(
      100000,
      mockPLPStaking,
      mockPLP,
      mockP88
    );

    rewardsTokenList.push(address(mockEsP88));
    rewardsTokenList.push(address(mockMatic));

    lockdrop = new Lockdrop(
      address(lockdropToken),
      lockdropStrategy,
      lockdropConfig,
      rewardsTokenList
    );
  }

  function testCorrectness_ClaimAllReward_WhenOnlyOneUser() external {
    vm.startPrank(ALICE, ALICE);
    lockdropToken.mint(ALICE, 20 ether);
    lockdropToken.approve(address(lockdrop), 20 ether);
    vm.warp(120000);
    lockdrop.lockToken(16 ether, 604900);
    vm.stopPrank();
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);

    assertEq(lockdropToken.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, 16 ether);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16 ether);

    // After the lockdrop period ends, owner can stake PLP
    vm.startPrank(address(lockdrop), address(lockdrop));
    vm.warp(704900);
    lockdropToken.approve(address(lockdropStrategy), 16 ether);
    lockdrop.stakePLP();

    mockPLP.mint(address(mockPLPStaking), 16 ether);
    mockPLP.approve(address(mockPLPStaking), 16 ether);

    mockMatic.mint(address(mockPLPStaking), 16 ether);
    mockMatic.approve(address(mockPLPStaking), 16 ether);

    mockEsP88.mint(address(mockPLPStaking), 16 ether);
    mockEsP88.approve(address(mockPLPStaking), 16 ether);
    vm.stopPrank();

    assertEq(lockdrop.totalPLPAmount(), 16 ether);

    assertEq(IERC20(mockMatic).balanceOf(address(mockPLPStaking)), 16 ether);
    assertEq(IERC20(mockEsP88).balanceOf(address(mockPLPStaking)), 16 ether);
    assertEq(IERC20(mockPLP).balanceOf(address(mockPLPStaking)), 16 ether);

    vm.startPrank(ALICE, ALICE);
    lockdrop.claimAllRewards(ALICE);
    vm.stopPrank();

    assertEq(IERC20(mockMatic).balanceOf(address(ALICE)), 16 ether);
    assertEq(IERC20(mockEsP88).balanceOf(address(ALICE)), 16 ether);
  }

  function testCorrectness_ClaimAllReward_WhenMoreThanOneUser() external {
    vm.startPrank(ALICE, ALICE);
    lockdropToken.mint(ALICE, 20 ether);
    lockdropToken.approve(address(lockdrop), 20 ether);
    vm.warp(120000);
    lockdrop.lockToken(16 ether, 604900);
    vm.stopPrank();
    (
      uint256 alicelockdropTokenAmount,
      uint256 alicelockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);

    assertEq(lockdropToken.balanceOf(ALICE), 4 ether);
    assertEq(alicelockdropTokenAmount, 16 ether);
    assertEq(alicelockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16 ether);

    vm.startPrank(BOB, BOB);
    lockdropToken.mint(BOB, 30 ether);
    lockdropToken.approve(address(lockdrop), 30 ether);

    vm.warp(130000);
    lockdrop.lockToken(29 ether, 605000);
    vm.stopPrank();
    (
      uint256 boblockdropTokenAmount,
      uint256 boblockPeriod,
      bool bobP88Claimed
    ) = lockdrop.lockdropStates(BOB);
    assertEq(boblockdropTokenAmount, 29 ether);
    assertEq(boblockPeriod, 605000);
    assertEq(lockdropToken.balanceOf(BOB), 1 ether);
    assertEq(lockdrop.totalAmount(), 45 ether);

    // After the lockdrop period ends, owner can stake PLP
    vm.startPrank(address(lockdrop), address(lockdrop));
    vm.warp(704900);
    lockdropToken.approve(address(lockdropStrategy), 45 ether);
    lockdrop.stakePLP();

    mockPLP.mint(address(mockPLPStaking), 45 ether);
    mockPLP.approve(address(mockPLPStaking), 45 ether);

    mockMatic.mint(address(mockPLPStaking), 100 ether);
    mockMatic.approve(address(mockPLPStaking), 100 ether);

    mockEsP88.mint(address(mockPLPStaking), 100 ether);
    mockEsP88.approve(address(mockPLPStaking), 100 ether);

    vm.stopPrank();

    assertEq(lockdrop.totalPLPAmount(), 45 ether);

    assertEq(IERC20(mockMatic).balanceOf(address(mockPLPStaking)), 100 ether);
    assertEq(IERC20(mockEsP88).balanceOf(address(mockPLPStaking)), 100 ether);
    assertEq(IERC20(mockPLP).balanceOf(address(mockPLPStaking)), 45 ether);

    vm.startPrank(ALICE, ALICE);
    lockdrop.claimAllRewards(ALICE);
    vm.stopPrank();

    vm.startPrank(BOB, BOB);
    lockdrop.claimAllRewards(BOB);
    vm.stopPrank();

    assertEq(IERC20(mockMatic).balanceOf(address(ALICE)), 16 ether);
    assertEq(IERC20(mockEsP88).balanceOf(address(ALICE)), 16 ether);
    assertEq(IERC20(mockMatic).balanceOf(address(BOB)), 29 ether);
    assertEq(IERC20(mockEsP88).balanceOf(address(BOB)), 29 ether);
  }
}
