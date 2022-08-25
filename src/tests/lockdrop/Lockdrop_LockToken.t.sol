// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console, MockErc20 } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_LockToken is Lockdrop_BaseTest {
  MockErc20 internal mock2ERC20;

  function setUp() public override {
    super.setUp();
    mock2ERC20 = new MockErc20("Mock Token2", "MT2", 18);
  }

  function testCorrectness_LockdropLockToken() external {
    // ------- Alice session -------
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    lockdrop.lockToken(16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();
    // After Alice lock the ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 4
    // 2. The amount of Alice's lockdrop token should be 16
    // 3. The number of lock period should be 604900
    // 4. The total amount of lock token should be 16
    // 5. The total P88 weight should be 16 * 604900
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // ------- Bob session -------
    vm.startPrank(BOB);
    mockERC20.mint(BOB, 30);
    mockERC20.approve(address(lockdrop), 30);
    vm.warp(lockdropConfig.startLockTimestamp() + 5 hours);
    lockdrop.lockToken(10, 704900);
    (uint256 bobLockdropTokenAmount, uint256 bobLockPeriod, ) = lockdrop
      .lockdropStates(BOB);
    vm.stopPrank();
    // After Bob lock the ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Bobs' ERC20 token should be 20
    // 2. The amount of Bobs' lockdrop token should be 10
    // 3. The number of lock period should be 704900
    // 4. The total amount of lock token should be 16 + 10 = 26
    // 5. The total P88 weight should be 16 * 604900 + 10 * 704900
    assertEq(mockERC20.balanceOf(BOB), 20);
    assertEq(bobLockdropTokenAmount, 10);
    assertEq(bobLockPeriod, 704900);
    assertEq(lockdrop.totalAmount(), 26);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900 + 10 * 704900);
  }

  function testCorrectness_LockdropLockToken_Relock() external {
    // ------- Alice session -------
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 100);
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    lockdrop.lockToken(16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    lockdrop.earlyWithdrawLockedToken(16, ALICE);

    lockdrop.lockToken(20, 40 days);
    (aliceLockdropTokenAmount, aliceLockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw all and relock, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 0
    // 2. The amount of Alice's lockdrop token should be 20
    // 3. The number of lock period should be 40 days
    // 4. The total amount of lock token should be 20
    // 5. The total P88 weight should be 20 * 40 days
    assertEq(mockERC20.balanceOf(ALICE), 0);
    assertEq(aliceLockdropTokenAmount, 20);
    assertEq(aliceLockPeriod, 40 days);
    assertEq(lockdrop.totalAmount(), 20);
    assertEq(lockdrop.totalP88Weight(), 20 * 40 days);
    vm.stopPrank();
  }

  function testCorrectness_LockdropAddLockAmount() external {
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Alice wants to lock more
    lockdrop.addLockAmount(4);
    vm.stopPrank();

    (aliceLockdropTokenAmount, aliceLockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice add more ERC20 token, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 0
    // 2. The amount of Alice's lockdrop token should be 20
    // 3. The number of lock period should be 604900
    // 4. The total amount of lock token should be 20
    // 5. The total P88 weight should be 20 * 604900
    assertEq(mockERC20.balanceOf(ALICE), 0);
    assertEq(aliceLockdropTokenAmount, 20);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 20);
    assertEq(lockdrop.totalP88Weight(), 20 * 604900);
  }

  function testCorrectness_LockdropExtendLockPeriod() external {
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    lockdrop.lockToken(16, 604900);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // Alice wants to extend her lock period
    lockdrop.extendLockPeriod(800000);
    vm.stopPrank();
    (aliceLockdropTokenAmount, aliceLockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );

    // After Alice extend her lock period, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 4
    // 2. The amount of Alice's lockdrop token should be 16
    // 3. The number of lock period should be 80000
    // 4. The total amount of lock token should be 16
    // 5. The total P88 weight should be 16 * 800000
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 800000);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 800000);
  }

  function testCorrectness_LockdropLockTokenFor_GatewayCalled() external {
    // ------- Alice session -------
    vm.startPrank(lockdropConfig.gatewayAddress());
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    // Assume that gateway already recieve token from Alice
    mockERC20.mint(lockdropConfig.gatewayAddress(), 20);
    mockERC20.approve(address(lockdrop), 20);
    lockdrop.lockTokenFor(16, 604900, ALICE);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();
    // After gateway lock Alice's ERC20 token, the following criteria needs to satisfy:
    // 1. The amount of Alice's lockdrop token should be 16
    // 2. The number of lock period should be 604900
    // 3. The total amount of lock token should be 16
    // 4. The total P88 weight should be 16 * 604900
    // 5. Gateway ERC20 should be 0
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);
    assertEq(mock2ERC20.balanceOf(lockdropConfig.gatewayAddress()), 0);
  }

  function testCorrectness_LockdropLockTokenFor_GatewayCalledRelock() external {
    // ------- Alice session -------
    vm.startPrank(lockdropConfig.gatewayAddress());
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    // Assume that gateway already recieve token from Alice
    mockERC20.mint(lockdropConfig.gatewayAddress(), 20);
    mockERC20.approve(address(lockdrop), 100);
    lockdrop.lockTokenFor(16, 604900, ALICE);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);

    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);
    assertEq(mock2ERC20.balanceOf(lockdropConfig.gatewayAddress()), 0);

    lockdrop.earlyWithdrawLockedToken(16, ALICE);

    lockdrop.lockTokenFor(20, 40 days, ALICE);
    (aliceLockdropTokenAmount, aliceLockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After Alice withdraw all and call gateway to relock, the following criteria needs to satisfy:
    // 1. Balance of Alice's ERC20 token should be 0
    // 2. The amount of Alice's lockdrop token should be 20
    // 3. The number of lock period should be 40 days
    // 4. The total amount of lock token should be 20
    // 5. The total P88 weight should be 20 * 40 days
    assertEq(mockERC20.balanceOf(ALICE), 0);
    assertEq(aliceLockdropTokenAmount, 20);
    assertEq(aliceLockPeriod, 40 days);
    assertEq(lockdrop.totalAmount(), 20);
    assertEq(lockdrop.totalP88Weight(), 20 * 40 days);
    vm.stopPrank();
  }

  function testCorrectness_AddLockAmountFor_GatewayCalled() external {
    // ------- Alice session -------
    vm.startPrank(lockdropConfig.gatewayAddress());
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    // Assume that gateway already recieve token from Alice
    mockERC20.mint(lockdropConfig.gatewayAddress(), 20);
    mockERC20.approve(address(lockdrop), 20);
    lockdrop.lockTokenFor(16, 604900, ALICE);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);
    assertEq(mock2ERC20.balanceOf(lockdropConfig.gatewayAddress()), 0);

    // Alice wants to lock more, done by gateway
    lockdrop.addLockAmountFor(4, ALICE);
    vm.stopPrank();

    (aliceLockdropTokenAmount, aliceLockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );
    // After gateway lock more ERC20 token for Alice, the following criteria needs to satisfy:
    // 1. The amount of Alice's lockdrop token should be 20
    // 2. The number of lock period should be 604900
    // 3. The total amount of lock token should be 20
    // 4. The total P88 weight should be 20 * 604900
    assertEq(aliceLockdropTokenAmount, 20);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 20);
    assertEq(lockdrop.totalP88Weight(), 20 * 604900);
  }

  function testCorrectness_LockdropExtendLockPeriodFor_GatewayCalled()
    external
  {
    // ------- Alice session -------
    vm.startPrank(lockdropConfig.gatewayAddress());
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    // Assume that gateway already recieve token from Alice
    mockERC20.mint(lockdropConfig.gatewayAddress(), 20);
    mockERC20.approve(address(lockdrop), 20);
    lockdrop.lockTokenFor(16, 604900, ALICE);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);
    assertEq(mock2ERC20.balanceOf(lockdropConfig.gatewayAddress()), 0);

    // Alice wants to extend her lock period done by gateway
    lockdrop.extendLockPeriodFor(800000, ALICE);
    vm.stopPrank();
    (aliceLockdropTokenAmount, aliceLockPeriod, ) = lockdrop.lockdropStates(
      ALICE
    );

    // After gateway extend lock period for Alice, the following criteria needs to satisfy:
    // 1. The amount of Alice's lockdrop token should be 16
    // 2. The number of lock period should be 604900
    // 3. The total amount of lock token should be 16
    // 4. The total P88 weight should be 16 * 800000
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 800000);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 800000);
  }

  function testRevert_LockdropLockToken_ExceedLockdropPeriod() external {
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 7 days);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotInLockdropPeriod()"));
    lockdrop.lockToken(16, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_DepositZeroToken() external {
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_ZeroAmountNotAllowed()"));
    lockdrop.lockToken(0, 604900);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_LockPeriodLessThan7Days() external {
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidLockPeriod()"));
    lockdrop.lockToken(16, 1);
    vm.stopPrank();
  }

  function testRevert_LockdropLockToken_LockPeriodMoreThan364Days() external {
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(lockdropConfig.startLockTimestamp() + 3 hours);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_InvalidLockPeriod()"));
    lockdrop.lockToken(16, 31622400);
    vm.stopPrank();
  }

  function testRevert_LockdropLockTokenFor_NotGatewayCalled() external {
    vm.startPrank(ALICE);
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    mockERC20.mint(lockdropConfig.gatewayAddress(), 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotGateway()"));
    lockdrop.lockTokenFor(16, 604900, ALICE);
    vm.stopPrank();
  }

  function testRevert_AddLockAmountFor_NotGatewayCalled() external {
    // ------- Alice session -------
    vm.startPrank(lockdropConfig.gatewayAddress());
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    // Assume that gateway already recieve token from Alice
    mockERC20.mint(lockdropConfig.gatewayAddress(), 20);
    mockERC20.approve(address(lockdrop), 20);
    lockdrop.lockTokenFor(16, 604900, ALICE);
    vm.stopPrank();
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotGateway()"));
    lockdrop.addLockAmountFor(4, ALICE);
    vm.stopPrank();
  }

  function testRevert_LockdropExtendLockPeriodFor_NotGatewayCalled() external {
    // ------- Alice session -------
    vm.startPrank(lockdropConfig.gatewayAddress());
    vm.warp(lockdropConfig.startLockTimestamp() + 4 hours);
    // Assume that gateway already recieve token from Alice
    mockERC20.mint(lockdropConfig.gatewayAddress(), 20);
    mockERC20.approve(address(lockdrop), 20);
    lockdrop.lockTokenFor(16, 604900, ALICE);
    (uint256 aliceLockdropTokenAmount, uint256 aliceLockPeriod, ) = lockdrop
      .lockdropStates(ALICE);
    vm.stopPrank();
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_NotGateway()"));
    lockdrop.extendLockPeriodFor(800000, ALICE);
    vm.stopPrank();
  }
}
