pragma solidity 0.8.14;

import { Lockdrop_BaseTest, console } from "./Lockdrop_BaseTest.t.sol";

contract Lockdrop_AllocateP88 is Lockdrop_BaseTest {
  function setUp() public override {
    super.setUp();
    mockP88Token.setMinter(address(lockdrop), true);
  }

  function testCorrectness_AllocateP88() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (
      uint256 aliceLockdropTokenAmount,
      uint256 aliceLockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // After lockdrop period
    // Mint P88
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);

    vm.startPrank(address(lockdrop), address(lockdrop));
    mockP88Token.mint(address(lockdrop), 100);
    vm.stopPrank();

    vm.startPrank(address(this), address(this));
    lockdrop.allocateP88(100);
    vm.stopPrank();

    // After lockdrop period ends, allocating P88 is called, the following criteria needs to satisfy:
    assertEq(lockdrop.totalP88(), 100);
    assertEq(mockP88Token.balanceOf(address(lockdrop)), 100);
  }

  function testRevert_AllocateP88_CallAllocateMultipleTimes() external {
    vm.startPrank(ALICE, ALICE);
    mockERC20.mint(ALICE, 20);
    mockERC20.approve(address(lockdrop), 20);
    vm.warp(120000);
    lockdrop.lockToken(16, 604900);
    (
      uint256 aliceLockdropTokenAmount,
      uint256 aliceLockPeriod,
      bool aliceP88Claimed
    ) = lockdrop.lockdropStates(ALICE);
    vm.stopPrank();
    assertEq(mockERC20.balanceOf(ALICE), 4);
    assertEq(aliceLockdropTokenAmount, 16);
    assertEq(aliceLockPeriod, 604900);
    assertEq(lockdrop.totalAmount(), 16);
    assertEq(lockdrop.totalP88Weight(), 16 * 604900);

    // After lockdrop period
    // Mint P88
    vm.warp(lockdropConfig.startLockTimestamp() + 5 days);

    vm.startPrank(address(lockdrop), address(lockdrop));
    mockP88Token.mint(address(lockdrop), 100);
    vm.stopPrank();

    vm.startPrank(address(this), address(this));
    lockdrop.allocateP88(100);
    vm.expectRevert(abi.encodeWithSignature("Lockdrop_AlreadyAllocateP88()"));
    lockdrop.allocateP88(100);
    vm.stopPrank();
  }
}
