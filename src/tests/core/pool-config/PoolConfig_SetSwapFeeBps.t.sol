// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetSwapFeeBpsTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetSwapFeeBps() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setSwapFeeBps(1, 1);

    vm.stopPrank();
  }

  function testRevert_WhenNewSwapFeeBpsMoreThanMaxSwapFeeBps() external {
    vm.expectRevert(abi.encodeWithSignature("PoolConfig_BadNewSwapFeeBps()"));
    poolConfig.setSwapFeeBps(501, 1);
  }

  function testRevert_WhenNewStableSwapFeeBpsMoreThanMaxSwapFeeBps() external {
    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_BadNewStableSwapFeeBps()")
    );
    poolConfig.setSwapFeeBps(1, 501);
  }

  function testCorrectness_WhenSetSwapFeeBpsSuccessfully() external {
    poolConfig.setSwapFeeBps(500, 500);
    assertEq(poolConfig.swapFeeBps(), 500);
    assertEq(poolConfig.stableSwapFeeBps(), 500);
  }
}
