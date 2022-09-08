// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetAllowLiquidatosTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetAllowLiquidators() external {
    address[] memory liquidators = new address[](1);
    liquidators[0] = ALICE;

    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setAllowLiquidators(liquidators, true);

    vm.stopPrank();
  }

  function testCorrectness_WhenSetAllowLiquidatorsSuccessfully() external {
    address[] memory liquidators = new address[](1);
    liquidators[0] = ALICE;

    poolConfig.setAllowLiquidators(liquidators, true);
    assertTrue(poolConfig.allowLiquidators(ALICE));
  }
}
