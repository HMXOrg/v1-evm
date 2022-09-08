// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetIsAllowAllLiquidatorsTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetIsAllowAllLiquidators() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setIsAllowAllLiquidators(true);

    vm.stopPrank();
  }

  function testCorrectness_WhenSetIsAllowAllLiquidatorsSuccessfully() external {
    poolConfig.setIsAllowAllLiquidators(true);
    assertTrue(poolConfig.isAllowAllLiquidators());
  }
}
