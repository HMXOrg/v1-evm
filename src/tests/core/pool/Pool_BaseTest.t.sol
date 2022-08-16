// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { BaseTest, console, stdError, PoolConfig, PoolMath, PoolOracle, Pool } from "../../base/BaseTest.sol";

abstract contract Pool_BaseTest is BaseTest {
  PoolConfig internal poolConfig;
  PoolMath internal poolMath;
  PoolOracle internal poolOracle;
  Pool internal pool;

  function setUp() public virtual {
    BaseTest.PoolConfigConstructorParams memory poolConfigParams = BaseTest
      .PoolConfigConstructorParams({
        fundingInterval: 8 hours,
        mintBurnFeeBps: 30,
        taxBps: 50,
        stableFundingRateFactor: 600,
        fundingRateFactor: 600,
        liquidityCoolDownPeriod: 1 days
      });

    (poolOracle, poolConfig, poolMath, pool) = deployFullPool(poolConfigParams);

    (
      address[] memory tokens,
      PoolOracle.PriceFeedInfo[] memory priceFeedInfo
    ) = buildDefaultSetPriceFeedInput();
    poolOracle.setPriceFeed(tokens, priceFeedInfo);
  }
}
