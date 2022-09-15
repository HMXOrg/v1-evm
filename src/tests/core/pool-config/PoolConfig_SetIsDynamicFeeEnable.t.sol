// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetIsDynamicFeeEnableTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTryToSetIsDynamicFeeEnable() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setIsDynamicFeeEnable(true);

    vm.stopPrank();
  }

  function testCorrectness_WhenSetIsDynamicFeeEnableSuccessfully() external {
    poolConfig.setIsDynamicFeeEnable(true);
    assertTrue(poolConfig.isDynamicFeeEnable());
  }
}
