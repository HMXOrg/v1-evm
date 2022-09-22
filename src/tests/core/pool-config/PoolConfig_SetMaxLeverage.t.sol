// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetMaxLeverageTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetMaxLeverage() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setMaxLeverage(100);

    vm.stopPrank();
  }

  function testRevert_WhenNewMaxLeverageLessThanMinLeverage() external {
    vm.expectRevert(abi.encodeWithSignature("PoolConfig_BadNewMaxLeverage()"));
    poolConfig.setMaxLeverage(100);
  }

  function testCorrectness_WhenSetNewMaxLeverageSuccessfully() external {
    poolConfig.setMaxLeverage(20000);
    assertEq(poolConfig.maxLeverage(), 20000);
  }
}
