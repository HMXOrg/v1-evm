// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetSwapEnableTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTryToSetIsSwapEnable() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setIsSwapEnable(true);

    vm.stopPrank();
  }

  function testCorrectness_WhenSetIsSwapEnableSuccessfully() external {
    poolConfig.setIsSwapEnable(false);
    assertFalse(poolConfig.isSwapEnable());
  }
}
