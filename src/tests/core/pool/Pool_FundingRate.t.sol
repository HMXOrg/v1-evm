// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Pool_BaseTest, console, Pool, PoolConfig } from "./Pool_BaseTest.t.sol";

contract Pool_FundingRateTest is Pool_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory configs
    ) = buildDefaultSetTokenConfigInput();

    poolConfig.setTokenConfigs(tokens, configs);
  }

  function testCorrectness_FundingRate() external {
    // Warp 8 hours so time not start with 0
    vm.warp(1662100761);

    // Initialized price feeds
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    // Assuming WBTC price is at 40,000 - 41,000 USD
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    // Add 0.0025 WBTC as a liquidity of the pool
    wbtc.mint(address(pool), 0.0025 * 10**8);
    pool.addLiquidity(address(this), address(wbtc), address(this));

    // The following conditions need to be met:
    // 1. Pool's AUM by min price should be:
    // 0.0025 * (1-0.003) * 40000 = 99.7 USD
    // 2. Pool's AUM by max price should be:
    // 0.0025 * (1-0.003) * 41000 = 102.1925 USD
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99.7 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 102.1925 * 10**18);

    // Increase long position with 0.00025 WBTC (=10 USD) as a collateral
    // With 9x leverage; Hence position's size should be 90 USD.
    wbtc.mint(address(pool), 0.00025 * 10**8);
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      90 * 10**30,
      Exposure.LONG
    );

    // The following conditions need to be met:
    // 1. Pool's liquidity should be:
    // = 0.0024925 + 0.00025 - ((90 * 0.001) / 41000)
    // = 0.0024925 + 0.00025 - (219 / 1e8)
    // = 0.00274031 WBTC
    // 2. Pool's WBTC's guaranteed USD should be:
    // = 90 + (90 * 0.001) - (0.00025 * 40000)
    // = 80.09 USD
    // 3. Pool's WBTC reserved should be:
    // = 90 / 40000 = 0.0025 WBTC
    // 4. Pool should make:
    // = 750 + 219
    // = 969 sathoshi
    // 5. Pool's AUM by min price should be:
    // = 80.09 + ((0.00274031 - 0.00225) * 40000)
    // 6. Pool's AUM by max price should be:
    // = 80.09 + ((0.00274031 - 0.00225) * 41000)
    assertEq(pool.liquidityOf(address(wbtc)), 0.00274031 * 10**8);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 80.09 * 10**30);
    assertEq(pool.reservedOf(address(wbtc)), 0.00225 * 10**8);
    assertEq(pool.feeReserveOf(address(wbtc)), 969);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99.7024 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 100.19271 * 10**18);

    // Assert position
    // 1. Position's size should be 90 USD
    // 2. Position's collateral should be:
    // = (0.00025 * 40000) - (90 * 0.001) = 9.91 USD
    // 3. Position's average price should be: 41000 USD
    // 4. Position's entry funding rate should be: 0
    // 5. Position's reserve amount should be: 90 / 41000 = 0.00225 USD
    Pool.GetPositionReturnVars memory position = pool.getPosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(position.size, 90 * 10**30);
    assertEq(position.collateral, 9.91 * 10**30);
    assertEq(position.averagePrice, 41000 * 10**30);
    assertEq(position.entryFundingRate, 0 * 10**30);
    assertEq(position.reserveAmount, 0.00225 * 10**8);

    // WBTC price chanaged
    wbtcPriceFeed.setLatestAnswer(45_100 * 10**8);
    wbtcPriceFeed.setLatestAnswer(46_100 * 10**8);
    wbtcPriceFeed.setLatestAnswer(47_100 * 10**8);

    // Assert position's delta
    // 1. Position's delta should be:
    // = 90 * ((45100 - 41000) / 41000)
    // = 9 USD
    // 2. Position is profitable
    (bool isProfit, uint256 delta) = pool.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(delta, 9 * 10**30);
    assertTrue(isProfit);

    // Assert position's leverage
    assertEq(
      pool.getPositionLeverage(
        address(this),
        0,
        address(wbtc),
        address(wbtc),
        Exposure.LONG
      ),
      90817
    );

    // Decrease position size 50 USD and collateral 3 USD
    pool.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      3 * 10**30,
      50 * 10**30,
      Exposure.LONG,
      BOB
    );

    // Assert pool's state
    // 1. Pool shoulud make:
    // = 969 + Trunc(((50 * 0.001) / 47100) * 1e8)
    // = 969 + 106 = 1079 sathoshi
    // 2. Pool's WBTC reserved should be 0.00225 * 40 / 90 = 0.001 WBTC
    // 3. Pool's guaranteed usd of WBTC should be:
    // = 80.90 + (9.91 - 6.91) - 50 = 33.09 USD
    // 4. Pool's WBTC liquidity should be:
    // = 0.00274031 - ((3 [CollateralDelta] + 5 [Profit]) / 47100)
    // = 0.00257046 WBTC
    // 5. Bob's WBTC balance should be:
    // = ((3 [CollateralDelta] + 5 [Profit] - 0.05 [MarginFee]) / 47100)
    // = 16878 sathoshi
    assertEq(pool.feeReserveOf(address(wbtc)), 1075);
    assertEq(pool.reservedOf(address(wbtc)), 0.001 * 10**8);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 33.09 * 10**30);
    assertEq(pool.liquidityOf(address(wbtc)), 0.00257046 * 10**8);
    assertEq(wbtc.balanceOf(BOB), 16878);

    // Assert position
    // 1. Position's size should be: 40 USD
    // 2. Position's collateral should be: 6.91 USD
    // 3. Position's average price should be: 41000 USD
    // 4. Position's entry funding rate should be: 0
    // 5. Position's reserve amount should be: 0.00225 * 40 / 90 = 0.001 WBTC
    // 6. Position's realized PnL should be: 5 USD
    // 7. Position should be profitable
    position = pool.getPosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(position.size, 40 * 10**30);
    assertEq(position.collateral, 6.91 * 10**30);
    assertEq(position.averagePrice, 41000 * 10**30);
    assertEq(position.entryFundingRate, 0 * 10**30);
    assertEq(position.reserveAmount, 0.001 * 10**8);
    assertEq(position.realizedPnl, 5 * 10**30);
    assertTrue(position.hasProfit);

    // Assert position's leverage
    assertEq(
      pool.getPositionLeverage(
        address(this),
        0,
        address(wbtc),
        address(wbtc),
        Exposure.LONG
      ),
      57887
    );

    // Warp to pass funding time interval
    vm.warp(block.timestamp + 8 hours + 1);

    // Withdraw collateral so postion get charged by the funding fee
    pool.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      1 * 10**30,
      0,
      Exposure.LONG,
      BOB
    );

    // Assert pool state:
    // 1. Pool shoulud make:
    // = 1075 + funding fee
    // Where funding fee is:
    // = 0.06% * 100000.0 / 257046.0
    // = 0.0233% --> Funding Rate
    // = 40 * 0.0233%
    // = 0.00932 USD --> Funding Fee USD
    // = 0.00932 / 47100 * 1e8
    // = 19 sats
    // Hence; 1075 + 19 = 1094 sathoshi
    // 2. Pool's WBTC reserved should remind the same.
    // 3. Pool's guaranteed usd of WBTC should be:
    // = 33.09 + (6.91 - 5.91) = 34.09 USD
    // 4. Pool's WBTC liquidity should be:
    // = 257046 - ((1 [CollateralDelta]) / 47100 * 1e8)
    // = 257046 - 2123
    // = 254923 WBTC
    // 5. Bob's WBTC balance should be:
    // = 16878 + (1 [CollateralDelta] / 47100 * 1e8) - fundingFee
    // = 16878 + 2123 - 19 - 1 (offset)
    // = 18982 sathoshi
    assertEq(pool.feeReserveOf(address(wbtc)), 1094);
    assertEq(pool.reservedOf(address(wbtc)), 0.001 * 10**8);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 34.09 * 10**30);
    assertEq(pool.liquidityOf(address(wbtc)), 254923);
    assertEq(wbtc.balanceOf(BOB), 18981);

    checkPoolBalanceWithState(address(wbtc), 2);
  }
}
