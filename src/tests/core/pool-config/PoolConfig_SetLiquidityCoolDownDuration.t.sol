// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetLiquidityCoolDownDurationTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTryToSetLiquidityCoolDownDuration() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setLiquidityCoolDownDuration(1 days);

    vm.stopPrank();
  }

  function testRevert_WhenNewLiquidityCoolDownDurationMoreThanMaxLiquidityCoolDownDuration()
    external
  {
    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_BadNewLiquidityCoolDownDuration()")
    );
    poolConfig.setLiquidityCoolDownDuration(100 days);
  }

  function testCorrectness_WhenSetLiquidityCoolDownDurationSuccessfully()
    external
  {
    poolConfig.setLiquidityCoolDownDuration(2 days);
    assertEq(poolConfig.liquidityCoolDownDuration(), 2 days);
  }
}
