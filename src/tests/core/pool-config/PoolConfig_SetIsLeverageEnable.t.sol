// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetIsLeverageEnableTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTryToSetIsLeverageEnable() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setIsLeverageEnable(true);

    vm.stopPrank();
  }

  function testCorrectness_WhenSetIsLeverageEnableSuccessfully() external {
    poolConfig.setIsLeverageEnable(false);
    assertFalse(poolConfig.isLeverageEnable());
  }
}
