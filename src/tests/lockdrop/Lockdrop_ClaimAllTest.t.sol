pragma solidity 0.8.14;

import { console } from "../utils/console.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { BaseTest, MockWNative } from "../base/BaseTest.sol";
import { LockdropConfig } from "../../lockdrop/LockdropConfig.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { MockPool } from "../mocks/MockPool.sol";
import { MockPLPStaking } from "../mocks/MockPLPStaking.sol";

contract Lockdrop_ClaimReward is BaseTest {
  using SafeERC20 for IERC20;

  MockErc20 internal mockPLP;
  MockErc20 internal mockP88;
  MockErc20 internal mockEsP88;
  MockWNative internal mockWMatic;
  MockErc20 internal lockdropToken;
  address[] internal rewardsTokenList;
  LockdropConfig internal lockdropConfig;
  Lockdrop internal lockdrop;
  MockPLPStaking internal mockPLPStaking;
  MockPool internal pool;
  address internal mockGateway;

  function setUp() external {
    mockGateway = address(0x88);
    pool = new MockPool();

    lockdropToken = new MockErc20("LockdropToken", "LCKT", 18);
    mockPLP = new MockErc20("PLP", "PLP", 18);
    mockP88 = new MockErc20("P88", "P88", 18);
    mockEsP88 = new MockErc20("EsP88", "EsP88", 18);
    mockWMatic = deployMockWNative();

    // mockWMatic.mint(address(this), 100 ether);
    // mockWMatic.approve(address(this), 100 ether);
    mockWMatic.deposit{ value: 100 ether }();

    mockPLPStaking = new MockPLPStaking(
      address(mockPLP),
      mockWMatic,
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
    rewardsTokenList.push(address(mockWMatic));

    lockdrop = new Lockdrop(
      address(lockdropToken),
      pool,
      lockdropConfig,
      rewardsTokenList,
      address(mockWMatic)
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

    // mint PLP tokens for PLPStaking
    mockPLP.mint(address(lockdrop), 62 ether);
    mockPLP.approve(address(lockdrop), 62 ether);

    vm.startPrank(address(lockdrop));
    mockPLP.approve(address(lockdropConfig.plpStaking()), 62 ether);
    vm.stopPrank();

    // After the lockdrop period ends, owner can stake PLP
    // Be Lockdrop contract.
    vm.startPrank(address(this));
    // after 7 days.
    vm.warp(block.timestamp + 7 days);
    // Lockdrop stake lockdrop tokens  in PLPstaking.
    lockdrop.stakePLP();
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
    mockWMatic.approve(address(mockPLPStaking), 10 ether);
    mockPLPStaking.feedRevenueReward(10 ether);

    assertEq(mockWMatic.balanceOf(address(mockPLPStaking)), 10 ether);

    // First Claim by Alice
    assertEq(mockWMatic.balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE, ALICE);
    lockdrop.claimAllRewardsFor(ALICE, ALICE);
    vm.stopPrank();

    assertGt(ALICE.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(ALICE), 0);

    // ALICE spend her reward
    vm.startPrank(ALICE);
    mockWMatic.approve(address(this), mockWMatic.balanceOf(ALICE));
    mockEsP88.approve(address(this), mockEsP88.balanceOf(ALICE));
    vm.stopPrank();

    vm.startPrank(address(this));

    mockWMatic.transferFrom(ALICE, address(this), mockWMatic.balanceOf(ALICE));

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
    lockdrop.claimAllRewardsFor(ALICE, ALICE);
    vm.stopPrank();
    assertEq(mockWMatic.balanceOf(ALICE), 0 ether);
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
    mockWMatic.approve(address(mockPLPStaking), 10 ether);
    mockPLPStaking.feedRevenueReward(10 ether);
    assertEq(mockWMatic.balanceOf(address(mockPLPStaking)), 10 ether);

    // First Claim

    // Claim by Alice
    assertEq(mockWMatic.balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewardsFor(ALICE, ALICE);
    vm.stopPrank();

    assertGt(ALICE.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(ALICE), 0);

    // Claim by BOB
    assertEq(mockWMatic.balanceOf(BOB), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(BOB), 0 ether);
    vm.startPrank(BOB);
    lockdrop.claimAllRewardsFor(BOB, BOB);
    vm.stopPrank();
    assertGt(BOB.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(BOB), 0);

    // Claim By CAT
    assertEq(mockWMatic.balanceOf(CAT), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(CAT), 0 ether);
    vm.startPrank(CAT);
    lockdrop.claimAllRewardsFor(CAT, CAT);
    vm.stopPrank();
    assertGt(BOB.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(BOB), 0);
  }

  function testCorrectness_ClaimAllReward_WhenMultipleUserWantToClaimInTheMultipleTime()
    external
  {
    assertEq(lockdrop.totalPLPAmount(), 62 ether);
    assertEq(lockdrop.totalAmount(), 31 ether);

    // after stake PLP token for 10 days
    // Feed Matic and EsP88 to PLPStaking
    vm.warp(block.timestamp + 10 days);
    mockWMatic.approve(address(mockPLPStaking), 10 ether);
    mockPLPStaking.feedRevenueReward(10 ether);
    assertEq(mockWMatic.balanceOf(address(mockPLPStaking)), 10 ether);

    // First Claim

    // Claim by Alice
    assertEq(mockWMatic.balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewardsFor(ALICE, ALICE);
    vm.stopPrank();
    assertGt(ALICE.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(ALICE), 0);

    // 1 Hr after ALICE claim
    vm.warp(block.timestamp + 1 hours);

    // Claim by BOB
    assertEq(mockWMatic.balanceOf(BOB), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(BOB), 0 ether);
    vm.startPrank(BOB);
    lockdrop.claimAllRewardsFor(BOB, BOB);
    vm.stopPrank();
    assertGt(BOB.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(BOB), 0);

    // 2 Hr after BOB
    vm.warp(block.timestamp + 2 hours);

    // Claim By CAT
    assertEq(mockWMatic.balanceOf(CAT), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(CAT), 0 ether);
    vm.startPrank(CAT);
    lockdrop.claimAllRewardsFor(CAT, CAT);
    vm.stopPrank();
    assertGt(CAT.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(CAT), 0);

    vm.warp(block.timestamp + 5 hours);

    // ALICE, BOB and CAT spend their reward.
    vm.startPrank(ALICE);
    mockWMatic.approve(address(this), mockWMatic.balanceOf(ALICE));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(ALICE));
    vm.stopPrank();

    vm.startPrank(BOB);
    mockWMatic.approve(address(this), mockWMatic.balanceOf(BOB));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(BOB));
    vm.stopPrank();

    vm.startPrank(CAT);
    mockWMatic.approve(address(this), mockWMatic.balanceOf(CAT));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(CAT));
    vm.stopPrank();

    vm.startPrank(address(this));

    mockWMatic.transferFrom(ALICE, address(this), mockWMatic.balanceOf(ALICE));

    IERC20(mockEsP88).safeTransferFrom(
      ALICE,
      address(this),
      IERC20(mockEsP88).balanceOf(ALICE)
    );

    mockWMatic.transferFrom(BOB, address(this), mockWMatic.balanceOf(BOB));

    IERC20(mockEsP88).safeTransferFrom(
      BOB,
      address(this),
      IERC20(mockEsP88).balanceOf(BOB)
    );

    mockWMatic.transferFrom(CAT, address(this), mockWMatic.balanceOf(CAT));

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
    assertEq(mockWMatic.balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewardsFor(ALICE, ALICE);
    vm.stopPrank();
    assertGt(ALICE.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(ALICE), 0);

    // Claim By CAT
    assertEq(mockWMatic.balanceOf(CAT), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(CAT), 0 ether);
    vm.startPrank(CAT);
    lockdrop.claimAllRewardsFor(CAT, CAT);
    vm.stopPrank();
    assertGt(CAT.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(CAT), 0);

    // ALICE, BOB and CAT spend their reward.
    vm.startPrank(ALICE);
    mockWMatic.approve(address(this), mockWMatic.balanceOf(ALICE));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(ALICE));
    vm.stopPrank();

    vm.startPrank(CAT);
    mockWMatic.approve(address(this), mockWMatic.balanceOf(CAT));
    mockEsP88.approve(address(this), IERC20(mockEsP88).balanceOf(CAT));
    vm.stopPrank();

    vm.startPrank(address(this));

    mockWMatic.transferFrom(ALICE, address(this), mockWMatic.balanceOf(ALICE));

    IERC20(mockEsP88).safeTransferFrom(
      ALICE,
      address(this),
      IERC20(mockEsP88).balanceOf(ALICE)
    );

    mockWMatic.transferFrom(CAT, address(this), mockWMatic.balanceOf(CAT));

    IERC20(mockEsP88).safeTransferFrom(
      CAT,
      address(this),
      IERC20(mockEsP88).balanceOf(CAT)
    );
    vm.stopPrank();

    // 2 days after first claim
    // Feed Matic to PLPStaking
    vm.warp(block.timestamp + 2 days);
    mockWMatic.approve(address(mockPLPStaking), 50 ether);
    mockPLPStaking.feedRevenueReward(50 ether);

    vm.warp(block.timestamp + 5 hours);

    // Claim by Alice
    assertEq(mockWMatic.balanceOf(ALICE), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(ALICE), 0 ether);
    vm.startPrank(ALICE);
    lockdrop.claimAllRewardsFor(ALICE, ALICE);
    vm.stopPrank();
    assertGt(ALICE.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(ALICE), 0);

    // 1 Hr after ALICE claim
    vm.warp(block.timestamp + 1 hours);

    // Claim by BOB
    assertEq(mockWMatic.balanceOf(BOB), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(BOB), 0 ether);
    vm.startPrank(BOB);
    lockdrop.claimAllRewardsFor(BOB, BOB);
    vm.stopPrank();
    assertGt(BOB.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(BOB), 0);

    // 2 Hr after BOB
    vm.warp(block.timestamp + 2 hours);

    // Claim By CAT
    assertEq(mockWMatic.balanceOf(CAT), 0 ether);
    assertEq(IERC20(mockEsP88).balanceOf(CAT), 0 ether);
    vm.startPrank(CAT);
    lockdrop.claimAllRewardsFor(CAT, CAT);
    vm.stopPrank();
    assertGt(CAT.balance, 0);
    assertGt(IERC20(mockEsP88).balanceOf(CAT), 0);
  }
}
