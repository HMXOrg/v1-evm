// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetLiquidationFeeUsdTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetLiquidationFeeUsd() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setLiquidationFeeUsd(100);

    vm.stopPrank();
  }

  function testRevert_WhenNewLiquidationFeeUsdMoreThanMaxLiquidationFeeUsd()
    external
  {
    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_BadNewLiquidationFeeUsd()")
    );
    poolConfig.setLiquidationFeeUsd(type(uint256).max);
  }

  function testCorrectness_WhenSetNewLiquidationFeeUsdSuccessfully() external {
    poolConfig.setLiquidationFeeUsd(20000);
    assertEq(poolConfig.liquidationFeeUsd(), 20000);
  }
}
