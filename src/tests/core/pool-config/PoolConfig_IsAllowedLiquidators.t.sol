// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_IsAllowedLiquidatorsTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_WhenAllowAnyoneToLiquidate() external {
    poolConfig.setIsAllowAllLiquidators(true);

    assertTrue(poolConfig.isAllowedLiquidators(ALICE));
    assertTrue(poolConfig.isAllowedLiquidators(BOB));
    assertTrue(poolConfig.isAllowedLiquidators(CAT));
  }

  function testCorrectness_WhenAllowWhitelistedLiquidatorsOnly() external {
    address[] memory liquidators = new address[](2);
    liquidators[0] = ALICE;
    liquidators[1] = BOB;

    poolConfig.setAllowLiquidators(liquidators, true);

    assertTrue(poolConfig.isAllowedLiquidators(ALICE));
    assertTrue(poolConfig.isAllowedLiquidators(BOB));
    assertFalse(poolConfig.isAllowedLiquidators(CAT));
  }
}
