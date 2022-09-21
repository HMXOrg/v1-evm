// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetRouterTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTryToSetRouter() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setRouter(BOB);

    vm.stopPrank();
  }

  function testCorrectness_WhenSetRouterSuccessfully() external {
    poolConfig.setRouter(BOB);
    assertEq(poolConfig.router(), BOB);
  }
}
