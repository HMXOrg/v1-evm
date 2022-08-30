// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Pool_BaseTest, console, Pool, PoolConfig } from "./Pool_BaseTest.t.sol";

contract Pool_LiquidateTest is Pool_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory tokenConfigs
    ) = buildDefaultSetTokenConfigInput();

    poolConfig.setTokenConfigs(tokens, tokenConfigs);
  }

  function testCorrectness_WhenLiquidateLongPosition() external {
    // Initialized price feed
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    // Feed WBTC price
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    // Add 0.0025 WBTC (0.0025 * 40,000 = 100 USD) as a liquidity
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
    // = 90 / 40000 = 0.00225 WBTC
    // 4. Pool should make:
    // = 750 + 219
    // = 969 sathoshi
    // 5. Pool's AUM by min price should be:
    // = 80.09 + ((0.00274031 - 0.00225) * 40000)
    // = 99.7024 USD
    // 6. Pool's AUM by max price should be:
    // = 80.09 + ((0.00274031 - 0.00225) * 41000)
    // = 102.19271 USD
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

    // Assert liquidation state of the position
    // 1. Position's liquidation state should be CANNOT_LIQUIDATE
    (LiquidationState liquidationState, ) = pool.poolMath().checkLiquidation(
      pool,
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG,
      false
    );
    assertTrue(liquidationState == LiquidationState.CANNOT_LIQUIDATE);

    // Assuming WBTC price up to 43,500 USD
    wbtcPriceFeed.setLatestAnswer(43_500 * 10**8);
    wbtcPriceFeed.setLatestAnswer(43_500 * 10**8);
    wbtcPriceFeed.setLatestAnswer(43_500 * 10**8);

    // Assert position's delta
    // 1. Position's delta should be:
    // = 90 * ((43500 - 41000) / 41000) = 5.48780487804878 USD
    // 2. Position should be profitable
    (bool isProfit, uint256 delta) = pool.getPositionDelta(
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(delta, 5487804878048780487804878048780);
    assertTrue(isProfit);

    // WBTC dropped sharply to 39,000 USD
    wbtcPriceFeed.setLatestAnswer(39_000 * 10**8);

    // Assert position's delta again, the pool should use min price from last 3 rounds
    // 1. Position's delta should be:
    // = 90 * ((39000 - 41000) / 41000) = -4.390243902439025 USD
    // 2. Position should be losses.
    (isProfit, delta) = pool.getPositionDelta(
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(delta, 4390243902439024390243902439024);
    assertFalse(isProfit);

    // WBTC dropped again to 38,700 USD
    wbtcPriceFeed.setLatestAnswer(38_700 * 10**8);

    // Assert position's delta again, the pool should use min price from last 3 rounds
    // 1. Position's delta should be:
    // = 90 * ((38700 - 41000) / 41000) = -5.048780487804878 USD
    // 2. Position should be losses.
    (isProfit, delta) = pool.getPositionDelta(
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(delta, 5048780487804878048780487804878);
    assertFalse(isProfit);

    // Allow anyone to liquidate the position
    assertFalse(poolConfig.isAllowAllLiquidators());
    poolConfig.setIsAllowAllLiquidators(true);
    assertTrue(poolConfig.isAllowAllLiquidators());

    // Assuming Bob is a liquidator
    // --- Start Bob session ---
    vm.startPrank(BOB);

    // Assert's pool AUM.
    // 1. Pool's AUM by min price should be:
    // = 80.09 + ((0.00274031 - 0.00225) * 38700)
    // = 99.064997 USD
    // 2. Pool's AUM by max price should be:
    // = 80.09 + ((0.00274031 - 0.00225) * 43500)
    // = 101.418485 USD
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99064997000000000000);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 101418485000000000000);

    pool.liquidate(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG,
      BOB
    );

    // The following conditions need to be met:
    // 1. Pool's liquidity should be:
    // = 0.00274031 - (90 * 0.001 / 43500) [Margin Fee] - (5 / 43500) [Liquidation Fee]
    // = 274031 sathoshi - 206 sathoshi - 11494 sathoshi
    // = 262331 sathoshi = 0.00262331 WBTC
    // 2. Pool's WBTC's guaranteed USD should be:
    // = 80.09 - (90 - 9.91)
    // = 0 USD
    // 3. Pool's WBTC reserved should be:
    // = 0.00225 - 0.00225
    // = 0 WBTC
    // 4. Pool should make:
    // = 969 + 206
    // = 1175 sathoshi
    // 5. Pool's AUM by min price should be:
    // = 0.00262331 * 38700
    // = 101.5220967 USD
    // 6. Pool's AUM by max price should be:
    // = 0.00262331 * 43500
    // = 114.113985 USD
    assertEq(pool.liquidityOf(address(wbtc)), 0.00262331 * 10**8);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 0);
    assertEq(pool.reservedOf(address(wbtc)), 0);
    assertEq(pool.feeReserveOf(address(wbtc)), 1175);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 101522097000000000000);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 114113985000000000000);

    // Assert position. Everything should be zero.
    position = pool.getPosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(position.primaryAccount, address(0));
    assertEq(position.size, 0);
    assertEq(position.collateral, 0);
    assertEq(position.averagePrice, 0);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 0);
    assertEq(position.realizedPnl, 0);
    assertTrue(position.hasProfit);
    assertEq(position.lastIncreasedTime, 0);

    // Assert that Bob received liquidate fee in WBTC
    assertEq(wbtc.balanceOf(BOB), 11494);

    vm.stopPrank();
    // --- Stop Bob session ---

    checkPoolBalanceWithState(address(wbtc), 0);
  }
}
