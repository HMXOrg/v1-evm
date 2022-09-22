// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { BaseTest, console, stdError, PoolConfig, PoolMath, PoolOracle, Pool } from "../../base/BaseTest.sol";

abstract contract PoolConfig_BaseTest is BaseTest {
  PoolConfig internal poolConfig;

  function setUp() public virtual {
    BaseTest.PoolConfigConstructorParams memory poolConfigParams = BaseTest
      .PoolConfigConstructorParams({
        treasury: TREASURY,
        fundingInterval: 8 hours,
        mintBurnFeeBps: 30,
        taxBps: 50,
        stableFundingRateFactor: 600,
        fundingRateFactor: 600,
        liquidationFeeUsd: 5 * 10**30
      });

    poolConfig = deployPoolConfig(poolConfigParams);
  }

  function assertTokenNotInLinkedlist(address token) internal {
    address tokenCursor = poolConfig.getNextAllowTokenOf(LINKEDLIST_START);
    while (tokenCursor != LINKEDLIST_END) {
      assertFalse(tokenCursor == token);
      tokenCursor = poolConfig.getNextAllowTokenOf(tokenCursor);
    }
  }

  function assertTokenInLinkedlist(address token) internal {
    address tokenCursor = poolConfig.getNextAllowTokenOf(LINKEDLIST_START);
    while (tokenCursor != LINKEDLIST_END) {
      if (tokenCursor == token) {
        assertTrue(tokenCursor == token);
        return;
      }
      tokenCursor = poolConfig.getNextAllowTokenOf(tokenCursor);
    }
  }
}
