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

  function testRevert_WhenNotWhitelistedLiquidatorTryToLiquidate() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_BadLiquidator()"));
    pool.liquidate(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG,
      address(this)
    );
  }

  function testRevert_WhenLiquidateHealthyPosition() external {
    // Initialized price feed
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    // Add 0.0025 WBTC (100 USD) as a liquidity
    wbtc.mint(address(pool), 0.0025 * 10**8);
    pool.addLiquidity(address(this), address(wbtc), address(this));

    // Open a 90 USD long position with 0.00025 WBTC (10 USD) as collateral
    wbtc.mint(address(pool), 0.00025 * 10**8);
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      90 * 10**30,
      Exposure.LONG
    );

    (LiquidationState liquidationState, ) = pool.poolMath().checkLiquidation(
      pool,
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG,
      false
    );
    assertTrue(liquidationState == LiquidationState.HEALTHY);
  }

  function testRevert_WhenLiquidatePositionZeroSize() external {
    // Initialized price feed
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    poolConfig.setIsAllowAllLiquidators(true);

    vm.expectRevert(abi.encodeWithSignature("Pool_BadPositionSize()"));
    pool.liquidate(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG,
      address(this)
    );
  }

  function testCorrectness_WhenLiquidateLongPosition_WhenSoftLiquidate()
    external
  {
    // Initialized price feed
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    // Set max leverage to 50x
    poolConfig.setMaxLeverage(50 * 10000);

    // Set WBTC price to be 40,000 - 41,000 USD
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    // Add 0.05 WBTC (2,000 USD) as a liquidity
    wbtc.mint(address(pool), 0.05 * 10**8);
    pool.addLiquidity(address(this), address(wbtc), address(this));

    // The following conditions should be met:
    // 1. Pool's liquidity should be:
    // = 0.05 * (1-0.003) = 0.04985 WBTC
    // 2. Pool should make:
    // = 0.05 * 0.003
    //  = 15000 sathoshi
    // 3. Pool's AUM by min price should be:
    // = 0.04985 * 40000
    // = 1994 USD
    // 4. Pool's AUM by max price should be:
    // = 0.04985 * 41000
    // = 2043.85 USD
    assertEq(pool.liquidityOf(address(wbtc)), 0.04985 * 10**8);
    assertEq(pool.feeReserveOf(address(wbtc)), 15000);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 1994 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 2043.85 * 10**18);

    // Open 1,000 USD long position with 0.0025 WBTC (100 USD) as a collateral
    wbtc.mint(address(pool), 0.0025 * 10**8);
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      1000 * 10**30,
      Exposure.LONG
    );

    // Assert pool's state:
    // 1. Pool's WBTC liquidity should be:
    // = 0.04985 + 0.0025 - (1000 * 0.001 / 41000)
    // = 4985000 sathoshi + 250000 sathoshi - 2439 sathoshi
    // = 5232561 sathoshi
    // 2. Pool should make:
    // = 15000 + 2439
    // = 17439 sathoshi
    // 3. Pool's WBTC reserved amount should be:
    // = 1000 / 40000
    // = 0.025 WBTC
    // 4. Pool's guaranteed USD should be:
    // = 1000 + (1000 * 0.001) - (0.0025 * 40000)
    // = 901 USD
    // 5. Pool's AUM by min price should be:
    // = 901 + (0.05232561 - 0.025) * 40000
    // = 1994.0244 USD
    // 6. Pool's AUM by max price should be:
    // = 901 + (0.05232561 - 0.025) * 41000
    // = 2021.35001 USD
    assertEq(pool.liquidityOf(address(wbtc)), 5232561);
    assertEq(pool.feeReserveOf(address(wbtc)), 17439);
    assertEq(pool.reservedOf(address(wbtc)), 0.025 * 10**8);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 901 * 10**30);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 1994.0244 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 2021.35001 * 10**18);

    // Assert position:
    // 1. Position size should be: 1,000 USD
    // 2. Position's collateral should be:
    // = 100 - (1000 * 0.001)
    // = 99 USD
    // 3. Position's average price should be 41,000 USD
    // 4. Position's entry funding rate should be: 0
    // 5. Position's reserved amount should be:
    // = 1000 / 40000 = 0.025 WBTC
    Pool.GetPositionReturnVars memory position = pool.getPosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(position.size, 1000 * 10**30);
    assertEq(position.collateral, 99 * 10**30);
    assertEq(position.averagePrice, 41_000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 0.025 * 10**8);

    (LiquidationState liquidationState, ) = pool.poolMath().checkLiquidation(
      pool,
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG,
      false
    );
    assertTrue(liquidationState == LiquidationState.HEALTHY);

    // Assuming price went up to 43,500
    wbtcPriceFeed.setLatestAnswer(43_500 * 10**8);
    wbtcPriceFeed.setLatestAnswer(43_500 * 10**8);
    wbtcPriceFeed.setLatestAnswer(43_500 * 10**8);

    // Assert position delta:
    // 1. Position delta should be:
    // = 1000 * ((43500 - 41000) / 41000)
    // = 60.97560975609756 USD
    // 2. Position should be profitable
    (bool isProfit, uint256 delta) = pool.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(delta, 60975609756097560975609756097560);
    assertTrue(isProfit);

    // Oracle feeds new price with 39000 USD
    wbtcPriceFeed.setLatestAnswer(39_000 * 10**8);

    // Assert position delta:
    // 1. Position delta should be:
    // = 1000 * ((39000 - 41000) / 41000)
    // = -48.78048780487805 USD
    // 2. Position should be loss
    (isProfit, delta) = pool.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(delta, 48780487804878048780487804878048);
    assertFalse(isProfit);

    // Oracle feeds 3 new prices
    wbtcPriceFeed.setLatestAnswer(37_760 * 10**8);
    wbtcPriceFeed.setLatestAnswer(37_760 * 10**8);
    wbtcPriceFeed.setLatestAnswer(37_760 * 10**8);

    // Assert position delta and check liquidation:
    // 1. Position delta should be:
    // = 1000 * ((37760 - 41000) / 41000)
    // = -79.02439024390245 USD
    // 2. Position should be loss
    (isProfit, delta) = pool.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(delta, 79024390243902439024390243902439);
    assertFalse(isProfit);

    // Assert liquidationState
    // 1. LiquidationState should be: SOFT_LIQUIDATE
    (liquidationState, ) = pool.poolMath().checkLiquidation(
      pool,
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG,
      false
    );
    assertTrue(liquidationState == LiquidationState.SOFT_LIQUIDATE);

    // Allow anyone to liquidate
    poolConfig.setIsAllowAllLiquidators(true);

    // --- Start Bob session ---
    // Assuming Bob try to liquidate
    vm.startPrank(BOB);

    pool.liquidate(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG,
      BOB
    );

    // Assert pool's state:
    // 1. Pool's liquidity should be:
    // = 5232561 sathoshi - (1000 * 0.001 / 37760) [Margin Fee] - [((99 -79.02439024390245) / 37760) - MarginFee] [Realized loss]
    // = 5232561 sathoshi - 2648 sathoshi - (52901 sathoshi - 2648 sathoshi)
    // = 5179660 sathoshi = 0.05179660 WBTC
    // 2. Pool's WBTC's guaranteed USD should be:
    // = 901 - (1000 - 99)
    // = 0 USD
    // 3. Pool's WBTC reserved should be:
    // = 0.025 - 0.025
    // = 0 WBTC
    // 4. Pool should make:
    // = 17439 + 2648
    // = 20087 sathoshi
    // 5. Pool's AUM by min price should be:
    // = 0.05179660 * 37760
    // = 1955.839616 USD
    // 6. Pool's AUM by max price should be:
    // = 0.05179660 * 37760
    // = 1955.839616 USD
    assertEq(pool.liquidityOf(address(wbtc)), 5179660);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 0);
    assertEq(pool.reservedOf(address(wbtc)), 0);
    assertEq(pool.feeReserveOf(address(wbtc)), 20087);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 1955.839616 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 1955.839616 * 10**18);

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

    // Assert WBTC balance.
    // 1. Position's primary account balance shoud be:
    // = [((99 -79.02439024390245) / 37760) - MarginFee]
    // = 50253 sathoshi
    // 2. Bob as a liquidator should get nothing here due to
    // it is a soft liquidation.
    assertEq(wbtc.balanceOf(address(this)), 50253);
    assertEq(wbtc.balanceOf(BOB), 0);

    checkPoolBalanceWithState(address(wbtc), 0);

    vm.stopPrank();
    // --- End Bob session ---
  }

  function testCorrectness_WhenLiquidateLongPosition_WhenLiquidate() external {
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
    assertTrue(liquidationState == LiquidationState.HEALTHY);

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

  function testCorrectness_WhenLiquidateShortPosition_WhenLiquidate() external {
    // Initialized price feeds
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    poolConfig.setMintBurnFeeBps(4);

    // Add 100 DAI as a liquidity to the pool
    dai.mint(address(pool), 100 * 10**18);
    pool.addLiquidity(address(this), address(dai), address(this));

    // The following conditions need to be met:
    // 1. Pool's AUM by min price should be:
    // = 100 * (1-0.004) = 99.96 USD
    // 2. Pool's AUM by max price should be:
    // = 100 * (1-0.004) = 99.96 USD
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99.96 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 99.96 * 10**18);

    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    // Open a new short position
    dai.mint(address(pool), 10 * 10**18);
    pool.increasePosition(
      address(this),
      0,
      address(dai),
      address(wbtc),
      90 * 10**30,
      Exposure.SHORT
    );

    // The following conditions need to be met:
    // 1. Pool's DAI liquidity should be 99.96 DAI
    // 2. Pool should makes:
    // = (100 * 0.0004) + (90 * 0.001)
    // = 0.13 DAI
    // 3. Pool's DAI reserved amount should be: 90 DAI
    // 4. Pool's DAI guaranteed USD should be 0
    // 5. Pool's AUM by min price should remain the same
    // As there is no price diff between min price and short avg price:
    // = 99.96 + (90 * (40000-40000) / 40000)
    // = 99.96
    // 6. Pool's AUM by max price should be:
    // = 99.96 + (90 * (41000 - 40000) / 40000)
    // = 102.21 USD
    // 7. Pool's WBTC short size should be 90 USD.
    // 8. Pool's WBTC average short price should be 40000 USD
    assertEq(pool.liquidityOf(address(dai)), 99.96 * 10**18);
    assertEq(pool.feeReserveOf(address(dai)), 0.13 * 10**18);
    assertEq(pool.reservedOf(address(dai)), 90 * 10**18);
    assertEq(pool.guaranteedUsdOf(address(dai)), 0);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99.96 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 102.21 * 10**18);
    assertEq(pool.shortSizeOf(address(wbtc)), 90 * 10**30);
    assertEq(pool.shortAveragePriceOf(address(wbtc)), 40000 * 10**30);

    // Assert position
    // 1. Position's size should be 90 USD
    // 2. Position's collateral should be:
    // = 10 - (90 * 0.001)
    // = 9.91 USD
    // 3. Position's average price should be:
    // = 40000 USD
    // 4. Position's entry funding rate should be 0.
    // 5. Position's reserve amount should be 100 DAI.
    // 5. Position's realized PnL should be 0.
    // 6. Position's should profitable as realized PnL is 0.
    Pool.GetPositionReturnVars memory position = pool.getPosition(
      address(this),
      0,
      address(dai),
      address(wbtc),
      Exposure.SHORT
    );
    assertEq(position.size, 90 * 10**30);
    assertEq(position.collateral, 9.91 * 10**30);
    assertEq(position.averagePrice, 40000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 90 * 10**18);
    assertEq(position.realizedPnl, 0);
    assertTrue(position.hasProfit);

    // Assert liquidation state of the position
    // 1. The position should be healthy
    (LiquidationState liquidationState, ) = pool.poolMath().checkLiquidation(
      pool,
      address(this),
      address(dai),
      address(wbtc),
      Exposure.SHORT,
      false
    );
    assertTrue(liquidationState == LiquidationState.HEALTHY);

    // Assuming WBTC prices drop to 39000 USD
    wbtcPriceFeed.setLatestAnswer(39_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(39_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(39_000 * 10**8);

    // Assert position's delta
    // 1. The position's delta should be
    // = 90 * ((40000 - 39000) / 40000)
    // = 2.25 USD
    // 2. The position should be profitable
    (bool isProfit, uint256 delta) = pool.getPositionDelta(
      address(this),
      0,
      address(dai),
      address(wbtc),
      Exposure.SHORT
    );
    assertEq(delta, 2.25 * 10**30);
    assertTrue(isProfit);

    // Assert position's liquidation state
    // 1. The position should be healthy
    (liquidationState, ) = pool.poolMath().checkLiquidation(
      pool,
      address(this),
      address(dai),
      address(wbtc),
      Exposure.SHORT,
      false
    );
    assertTrue(liquidationState == LiquidationState.HEALTHY);

    // Oracle feeds the new round of WBTC price to be 41000 USD
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);

    // Assert position's delta
    // 1. The position's delta should be
    // = 90 * ((40000 - 41000) / 40000)
    // = -2.25 USD
    // 2. The position should be unprofitable
    (isProfit, delta) = pool.getPositionDelta(
      address(this),
      0,
      address(dai),
      address(wbtc),
      Exposure.SHORT
    );
    assertEq(delta, 2.25 * 10**30);
    assertFalse(isProfit);

    // Assert position's liquidation state
    // 1. The position should be healthy
    (liquidationState, ) = pool.poolMath().checkLiquidation(
      pool,
      address(this),
      address(dai),
      address(wbtc),
      Exposure.SHORT,
      false
    );
    assertTrue(liquidationState == LiquidationState.HEALTHY);

    // Oracle feeds a new price to be 42500 USD
    wbtcPriceFeed.setLatestAnswer(42500 * 10**8);

    // Assert position's delta
    // 1. The position's delta should be
    // = 90 * ((40000 - 42500) / 40000)
    // = -5.625 USD
    // 2. The position should be unprofitable
    (isProfit, delta) = pool.getPositionDelta(
      address(this),
      0,
      address(dai),
      address(wbtc),
      Exposure.SHORT
    );
    assertEq(delta, 5.625 * 10**30);
    assertFalse(isProfit);

    // Assert position's liquidation state
    // 1. The position should be liquidatable
    (liquidationState, ) = pool.poolMath().checkLiquidation(
      pool,
      address(this),
      address(dai),
      address(wbtc),
      Exposure.SHORT,
      false
    );
    assertTrue(liquidationState == LiquidationState.LIQUIDATE);

    // Enable anyone to be a liquidator
    poolConfig.setIsAllowAllLiquidators(true);

    // Bob try to liquidate the position
    // --- Start Bob session ---
    vm.startPrank(BOB);

    pool.liquidate(
      address(this),
      0,
      address(dai),
      address(wbtc),
      Exposure.SHORT,
      BOB
    );

    vm.stopPrank();
    // --- End Bob session ---

    // Assert pool's state
    // 1. Pool's DAI liquidity should be
    // = 99.96 + (9.91 [Collateral] - (90 * 0.001) [MarginFee]) - 5 [Liquidation Fee]
    // = 104.78 DAI
    // 2. Pool should makes:
    // = 0.13 + (90 * 0.001)
    // = 0.22 DAI
    // 3. Pool's DAI reserved amount should be: 0 DAI
    // 4. Pool's AUM by min price should remain the same
    // As there is no price diff between min price and short avg price:
    // = 104.78 USD
    // 5. Pool's AUM by max price should be:
    // = 104.78 USD
    // 6. Pool's WBTC short size should be 0 USD.
    // 7. Pool's WBTC average short price should be 40000 USD
    assertEq(pool.liquidityOf(address(dai)), 104.78 * 10**18);
    assertEq(pool.feeReserveOf(address(dai)), 0.22 * 10**18);
    assertEq(pool.reservedOf(address(dai)), 0);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 104.78 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 104.78 * 10**18);
    assertEq(pool.shortSizeOf(address(wbtc)), 0);
    assertEq(pool.shortAveragePriceOf(address(wbtc)), 40000 * 10**30);

    // Set WBTC prices to be 50,000 USD
    wbtcPriceFeed.setLatestAnswer(50_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(50_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(50_000 * 10**8);

    // Try increase a new position
    dai.mint(address(pool), 20 * 10**18);
    pool.increasePosition(
      address(this),
      0,
      address(dai),
      address(wbtc),
      100 * 10**30,
      Exposure.SHORT
    );

    // Assert pool's state
    // 1. Pool's short size should be 100 USD
    // 2. Pool's short average price should be 50,000 USD
    // 3. Pool's AUM by min price should be:
    // = 104.78 - 100 + 100
    assertEq(pool.shortSizeOf(address(wbtc)), 100 * 10**30);
    assertEq(pool.shortAveragePriceOf(address(wbtc)), 50_000 * 10**30);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 104.78 * 10**18);

    position = pool.getPosition(
      address(this),
      0,
      address(dai),
      address(wbtc),
      Exposure.SHORT
    );
    checkPoolBalanceWithState(
      address(dai),
      (position.collateral * 10**18) / 10**30
    );
  }
}
