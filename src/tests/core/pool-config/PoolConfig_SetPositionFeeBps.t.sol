// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetPositionFeeBpsTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetPositionFeeBps() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setPositionFeeBps(1);

    vm.stopPrank();
  }

  function testRevert_WhenNewPositionFeeBpsMoreThanMaxPositionFeeBps()
    external
  {
    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_BadNewPositionFeeBps()")
    );
    poolConfig.setPositionFeeBps(501);
  }

  function testCorrectness_WhenSetPositionFeeBpsSuccessfully() external {
    poolConfig.setPositionFeeBps(500);

    assertEq(poolConfig.positionFeeBps(), 500);
  }
}
