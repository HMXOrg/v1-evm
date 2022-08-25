pragma solidity 0.8.14;

import { console } from "../utils/console.sol";
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
  address internal mockGateway;

  function setUp() external {
    lockdropStrategy = new MockLockdropStrategy();
    mockGateway = address(0x88);

    lockdropToken = new MockErc20("LockdropToken", "LCKT", 18);
    mockPLP = new MockErc20("PLP", "PLP", 18);
    mockP88 = new MockErc20("P88", "P88", 18);
    mockEsP88 = new MockErc20("EsP88", "EsP88", 18);
    mockMatic = new MockErc20("MATIC", "MATIC", 18);

    mockMatic.mint(address(this), 100 ether);
    mockMatic.approve(address(this), 100 ether);

    mockPLPStaking = new MockPLPStaking(
      address(mockPLP),
      address(mockMatic),
      address(mockEsP88)
    );

    lockdropConfig = new LockdropConfig(
      1 days,
      mockPLPStaking,
      mockPLP,
      mockP88,
      mockGateway
    );

    rewardsTokenList.push(address(mockEsP88));
    rewardsTokenList.push(address(mockMatic));

    lockdrop = new Lockdrop(
      address(lockdropToken),
      lockdropStrategy,
      lockdropConfig,
      rewardsTokenList
    );

    // Be Alice
    vm.startPrank(ALICE);
    // mint lockdrop token for ALICE
    lockdropToken.mint(ALICE, 20 ether);
    lockdropToken.approve(address(lockdrop), 20 ether);

    vm.stopPrank();

    // Be BOB
    vm.startPrank(BOB);
    // mint lockdrop token for BOB
    lockdropToken.mint(BOB, 20 ether);
    lockdropToken.approve(address(lockdrop), 20 ether);

    vm.stopPrank();

    // Be CAT
    vm.startPrank(CAT);
    // mint lockdrop token for BOB
    lockdropToken.mint(CAT, 20 ether);
    lockdropToken.approve(address(lockdrop), 20 ether);

    vm.stopPrank();

    // after 1 day
    vm.warp(block.timestamp + 1 days);

    vm.startPrank(ALICE);
    // ALICE Lock token for 7 days
    lockdrop.lockToken(16 ether, 7 days);
    vm.stopPrank();

    vm.startPrank(BOB);
    // BOB Lock token for 7 days
    lockdrop.lockToken(10 ether, 7 days);
    vm.stopPrank();

    vm.startPrank(CAT);
    // CAT Lock token for 7 days
    lockdrop.lockToken(5 ether, 7 days);
    vm.stopPrank();

    // After the lockdrop period ends, owner can stake PLP
    // Be Lockdrop contract.
    vm.startPrank(address(this));
    // after 7 days.
    vm.warp(block.timestamp + 7 days);

    // Lockdrop stake lockdrop tokens  in PLPstaking.
    lockdropToken.approve(address(lockdropStrategy), 31 ether);
    lockdrop.stakePLP();

    // mint PLP tokens for PLPStaking
    mockPLP.mint(address(mockPLPStaking), 62 ether);
    mockPLP.approve(address(mockPLPStaking), 62 ether);

    vm.stopPrank();
  }

  function testCorrectness_ClaimAllReward_WhenOnlyOneUserWantToClaimTwiceInADay_ThenTheSecondClaimWillGetOnlyEsP88()
    external
  {
    assertEq(lockdrop.totalPLPAmount(), 62 ether);
    assertEq(lockdrop.totalAmount(), 31 ether);

    // after stake PLP token for 10 days
    // Feed Matic and EsP88 to PLPStaking
    vm.warp(block.timestamp + 10 days);
    mockMatic.approve(address(mockPLPStaking), 10 ether);
    mockPLPStaking.feedRevenueReward(10 ether);

    assertEq(IERC20(mockMatic).balanceOf(address(mockPLPStaking)), 10 ether);

    // First Claim by Alice
    assertEq(IERC20(mockMatic).balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE, ALICE);
    lockdrop.claimAllRewards(ALICE);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(ALICE) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(ALICE) > 0);

    // ALICE spend her reward
    vm.startPrank(ALICE);
    mockMatic.approve(address(this), IERC20(mockMatic).balanceOf(ALICE));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(ALICE));
    vm.stopPrank();

    vm.startPrank(address(this));

    IERC20(mockMatic).safeTransferFrom(
      ALICE,
      address(this),
      IERC20(mockMatic).balanceOf(ALICE)
    );

    IERC20(mockEsP88).safeTransferFrom(
      ALICE,
      address(this),
      IERC20(mockEsP88).balanceOf(ALICE)
    );
    vm.stopPrank();

    // after 10 minute
    // ALICE want to claim again but she will get only EsP88
    vm.warp(block.timestamp + 10 minutes);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewards(ALICE);
    vm.stopPrank();
    assertEq(IERC20(mockMatic).balanceOf(ALICE), 0 ether);
    assertTrue(IERC20(mockEsP88).balanceOf(ALICE) > 0);
  }

  function testCorrectness_ClaimAllReward_WhenMultipleUserWantToClaimInTheSameTime()
    external
  {
    assertEq(lockdrop.totalPLPAmount(), 62 ether);
    assertEq(lockdrop.totalAmount(), 31 ether);

    // after stake PLP token for 10 days
    // Feed Matic and EsP88 to PLPStaking
    vm.warp(block.timestamp + 10 days);
    mockMatic.approve(address(mockPLPStaking), 10 ether);
    mockPLPStaking.feedRevenueReward(10 ether);
    assertEq(IERC20(mockMatic).balanceOf(address(mockPLPStaking)), 10 ether);

    // First Claim

    // Claim by Alice
    assertEq(IERC20(mockMatic).balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewards(ALICE);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(ALICE) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(ALICE) > 0);

    // Claim by BOB
    assertEq(IERC20(mockMatic).balanceOf(BOB), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(BOB), 0 ether);
    vm.startPrank(BOB);
    lockdrop.claimAllRewards(BOB);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(BOB) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(BOB) > 0);

    // Claim By CAT
    assertEq(IERC20(mockMatic).balanceOf(CAT), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(CAT), 0 ether);
    vm.startPrank(CAT);
    lockdrop.claimAllRewards(CAT);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(CAT) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(CAT) > 0);
  }

  function testCorrectness_ClaimAllReward_WhenMultipleUserWantToClaimInTheMultipleTime()
    external
  {
    assertEq(lockdrop.totalPLPAmount(), 62 ether);
    assertEq(lockdrop.totalAmount(), 31 ether);

    // after stake PLP token for 10 days
    // Feed Matic and EsP88 to PLPStaking
    vm.warp(block.timestamp + 10 days);
    mockMatic.approve(address(mockPLPStaking), 10 ether);
    mockPLPStaking.feedRevenueReward(10 ether);
    assertEq(IERC20(mockMatic).balanceOf(address(mockPLPStaking)), 10 ether);

    // First Claim

    // Claim by Alice
    assertEq(IERC20(mockMatic).balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewards(ALICE);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(ALICE) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(ALICE) > 0);

    // 1 Hr after ALICE claim
    vm.warp(block.timestamp + 1 hours);

    // Claim by BOB
    assertEq(IERC20(mockMatic).balanceOf(BOB), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(BOB), 0 ether);
    vm.startPrank(BOB);
    lockdrop.claimAllRewards(BOB);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(BOB) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(BOB) > 0);

    // 2 Hr after BOB
    vm.warp(block.timestamp + 2 hours);

    // Claim By CAT
    assertEq(IERC20(mockMatic).balanceOf(CAT), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(CAT), 0 ether);
    vm.startPrank(CAT);
    lockdrop.claimAllRewards(CAT);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(CAT) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(CAT) > 0);

    vm.warp(block.timestamp + 5 hours);

    // ALICE, BOB and CAT spend their reward.
    vm.startPrank(ALICE);
    mockMatic.approve(address(this), IERC20(mockMatic).balanceOf(ALICE));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(ALICE));
    vm.stopPrank();

    vm.startPrank(BOB);
    mockMatic.approve(address(this), IERC20(mockMatic).balanceOf(BOB));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(BOB));
    vm.stopPrank();

    vm.startPrank(CAT);
    mockMatic.approve(address(this), IERC20(mockMatic).balanceOf(CAT));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(CAT));
    vm.stopPrank();

    vm.startPrank(address(this));

    IERC20(mockMatic).safeTransferFrom(
      ALICE,
      address(this),
      IERC20(mockMatic).balanceOf(ALICE)
    );

    IERC20(mockEsP88).safeTransferFrom(
      ALICE,
      address(this),
      IERC20(mockEsP88).balanceOf(ALICE)
    );

    IERC20(mockMatic).safeTransferFrom(
      BOB,
      address(this),
      IERC20(mockMatic).balanceOf(BOB)
    );

    IERC20(mockEsP88).safeTransferFrom(
      BOB,
      address(this),
      IERC20(mockEsP88).balanceOf(BOB)
    );

    IERC20(mockMatic).safeTransferFrom(
      CAT,
      address(this),
      IERC20(mockMatic).balanceOf(CAT)
    );

    IERC20(mockEsP88).safeTransferFrom(
      CAT,
      address(this),
      IERC20(mockEsP88).balanceOf(CAT)
    );
    vm.stopPrank();

    // 10 days after each first claim
    // Matic not yet feed from rewarder.
    // ALICE and CAT need To claim but they will get just only EsP88

    // Claim by Alice
    assertEq(IERC20(mockMatic).balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewards(ALICE);
    vm.stopPrank();
    assertEq(IERC20(mockMatic).balanceOf(ALICE), 0 ether);
    assertTrue(IERC20(mockEsP88).balanceOf(ALICE) > 0);

    // Claim By CAT
    assertEq(IERC20(mockMatic).balanceOf(CAT), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(CAT), 0 ether);
    vm.startPrank(CAT);
    lockdrop.claimAllRewards(CAT);
    vm.stopPrank();
    assertEq(IERC20(mockMatic).balanceOf(CAT), 0 ether);
    assertTrue(IERC20(mockEsP88).balanceOf(CAT) > 0);

    // ALICE, BOB and CAT spend their reward.
    vm.startPrank(ALICE);
    mockMatic.approve(address(this), IERC20(mockMatic).balanceOf(ALICE));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(ALICE));
    vm.stopPrank();

    vm.startPrank(CAT);
    mockMatic.approve(address(this), IERC20(mockMatic).balanceOf(CAT));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(CAT));
    vm.stopPrank();

    vm.startPrank(address(this));

    IERC20(mockMatic).safeTransferFrom(
      ALICE,
      address(this),
      IERC20(mockMatic).balanceOf(ALICE)
    );

    IERC20(mockEsP88).safeTransferFrom(
      ALICE,
      address(this),
      IERC20(mockEsP88).balanceOf(ALICE)
    );

    IERC20(mockMatic).safeTransferFrom(
      CAT,
      address(this),
      IERC20(mockMatic).balanceOf(CAT)
    );

    IERC20(mockEsP88).safeTransferFrom(
      CAT,
      address(this),
      IERC20(mockEsP88).balanceOf(CAT)
    );
    vm.stopPrank();

    // 2 days after first claim
    // Feed Matic to PLPStaking
    vm.warp(block.timestamp + 2 days);
    mockMatic.approve(address(mockPLPStaking), 50 ether);
    mockPLPStaking.feedRevenueReward(50 ether);

    vm.warp(block.timestamp + 5 hours);

    // Claim by Alice
    assertEq(IERC20(mockMatic).balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewards(ALICE);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(ALICE) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(ALICE) > 0);

    // 1 Hr after ALICE claim
    vm.warp(block.timestamp + 1 hours);

    // Claim by BOB
    assertEq(IERC20(mockMatic).balanceOf(BOB), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(BOB), 0 ether);
    vm.startPrank(BOB);
    lockdrop.claimAllRewards(BOB);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(BOB) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(BOB) > 0);

    // 2 Hr after BOB
    vm.warp(block.timestamp + 2 hours);

    // Claim By CAT
    assertEq(IERC20(mockMatic).balanceOf(CAT), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(CAT), 0 ether);
    vm.startPrank(CAT);
    lockdrop.claimAllRewards(CAT);
    vm.stopPrank();
    assertTrue(IERC20(mockMatic).balanceOf(CAT) > 0);
    assertTrue(IERC20(mockEsP88).balanceOf(CAT) > 0);
  }
}
