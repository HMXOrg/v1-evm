// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Pool_BaseTest, console, Pool, PoolConfig } from "./Pool_BaseTest.t.sol";

contract Pool_DecreasePositionTest is Pool_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory configs
    ) = buildDefaultSetTokenConfigInput();

    poolConfig.setTokenConfigs(tokens, configs);
  }

  function testRevert_WhenMsgSenderNotAllowed() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_Forbidden()"));
    pool.decreasePosition(
      ALICE,
      0,
      address(dai),
      address(wbtc),
      0,
      0,
      Exposure.SHORT,
      ALICE
    );
  }

  function testRevert_WhenPositionNotExisted() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_BadPositionSize()"));
    pool.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      0,
      0,
      Exposure.LONG,
      address(this)
    );
  }

  function testRevert_WhenSizeDeltaLargerThanPositionSize() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);

    wbtc.mint(address(pool), 100 * 10**8);
    pool.addLiquidity(address(this), address(wbtc), address(this));

    // Increase long position with 0.2 WBTC as a collateral, and size to be
    // 0.2 * 5 (leverage) * 40000 = 1,000,000 WBTC
    wbtc.mint(address(pool), 0.2 * 10**8);
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      100_000 * 10**30,
      Exposure.LONG
    );

    vm.expectRevert(abi.encodeWithSignature("Pool_BadSizeDelta()"));
    pool.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      0,
      100_001 * 10**30,
      Exposure.LONG,
      address(this)
    );
  }

  function testRevert_WhenCollateralDeltaLargerThanPositionCollateral()
    external
  {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);

    wbtc.mint(address(pool), 100 * 10**8);
    pool.addLiquidity(address(this), address(wbtc), address(this));

    // Increase long position with 0.2 WBTC as a collateral, and size to be
    // 0.2 * 5 (leverage) * 40000 = 1,000,000 WBTC
    wbtc.mint(address(pool), 0.2 * 10**8);
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      100_000 * 10**30,
      Exposure.LONG
    );

    vm.expectRevert(abi.encodeWithSignature("Pool_BadCollateralDelta()"));
    pool.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      8_001 * 10**30,
      0,
      Exposure.LONG,
      address(this)
    );
  }

  function testCorrectness_WhenLong_WhenProfitable() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);

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

    // Mint WBTC to Alice
    wbtc.mint(ALICE, 0.00025 * 10**8);

    // --- Start Alice session ---
    vm.startPrank(ALICE);

    // Increase long position with 0.00025 WBTC (=10 USD) as a collateral
    // With 9x leverage; Hence position's size should be 90 USD.
    wbtc.transfer(address(pool), 0.00025 * 10**8);
    pool.increasePosition(
      ALICE,
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
      ALICE,
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

    vm.stopPrank();
    // --- End Alice session ---

    // WBTC price dump by 1 USD
    wbtcPriceFeed.setLatestAnswer((41_000 - 1) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 - 1) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 - 1) * 10**8);

    (bool isProfit, uint256 delta) = pool.getPositionDelta(
      ALICE,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(!isProfit);
    assertEq(delta, 2195121951219512195121951219);

    // WBTC price up 0.75%, 41000 * 0.75% = 307.5 USD
    wbtcPriceFeed.setLatestAnswer((41_000 + 307.5) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 + 307.5) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 + 307.5) * 10**8);

    (isProfit, delta) = pool.getPositionDelta(
      ALICE,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(isProfit);
    assertEq(delta, 0);

    // WBTC price +308 USD
    wbtcPriceFeed.setLatestAnswer((41_000 + 308) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 + 308) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 + 308) * 10**8);

    (isProfit, delta) = pool.getPositionDelta(
      ALICE,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(isProfit);
    assertEq(delta, 676097560975609756097560975609);

    // WBTC price changes again
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(45_100 * 10**8);

    (isProfit, delta) = pool.getPositionDelta(
      ALICE,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(!isProfit);
    assertEq(delta, 2195121951219512195121951219512);

    wbtcPriceFeed.setLatestAnswer(46_100 * 10**8);

    (isProfit, delta) = pool.getPositionDelta(
      ALICE,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(!isProfit);
    assertEq(delta, 2195121951219512195121951219512);

    wbtcPriceFeed.setLatestAnswer(47_100 * 10**8);

    (isProfit, delta) = pool.getPositionDelta(
      ALICE,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(isProfit);
    assertEq(delta, 9 * 10**30);

    // Assert position leverage
    assertEq(
      pool.getPositionLeverage(
        ALICE,
        address(wbtc),
        address(wbtc),
        Exposure.LONG
      ),
      90817
    );

    // Assert AUM
    // 1. Pool's AUM by min price shoud be:
    // = 80.09 + ((0.00274031 - 0.00225) * 45100)
    // = 102.202981 USD
    // 2. Pool's AUM by max price should be:
    // = 80.09 + ((0.00274031 - 0.00225) * 47100)
    // = 103.183601 USD
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 102.202981 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 103.183601 * 10**18);

    // --- Start Alice session ---
    vm.startPrank(ALICE);

    // Alice performs decrease position
    pool.decreasePosition(
      ALICE,
      0,
      address(wbtc),
      address(wbtc),
      3 * 10**30,
      50 * 10**30,
      Exposure.LONG,
      BOB
    );

    // The following conditions must be met:
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 103.917746 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 107.058666 * 10**18);
    assertEq(
      pool.getPositionLeverage(
        ALICE,
        address(wbtc),
        address(wbtc),
        Exposure.LONG
      ),
      57887
    );

    // Assert position
    // 1. Position's size should be: 40 USD
    // 2. Position's collateral should be: 6.91 USD
    // 3. Position's average price should be: 41000 USD
    // 4. Position's entry funding rate should be: 0
    // 5. Position's reserve amount should be: 0.00225 * 40 / 90 = 0.001 WBTC
    // 6. Position's realized PnL should be: 5 USD
    // 7. Position should be profitable
    position = pool.getPosition(
      ALICE,
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

    // Assert pool's state
    // 1. Pool shoulud make:
    // = 969 + Trunc(((50 * 0.001) / 47100) * 1e8)
    // = 969 + 106 = 1079 sathoshi
    // 2. Pool's WBTC reserved should be 0.00225 * 40 / 90 = 0.001 WBTC
    // 3. Pool's guaranteed usd of WBTC should be:
    // = 80.90 + (9.91 - 6.91) - 50 = 33.9 USD
    // 4. Pool's WBTC liquidity should be:
    // = 0.00274031 - ((3 [CollateralDelta] + 5 [Profit]) / 47100)
    // = 0.00257046 WBTC
    // 5. Bob's WBTC balance should be:
    // = ((3 [CollateralDelta] + 5 [Profit] - 0.05 [MarginFee]) / 47100)
    // = 16985 sathoshi
    assertEq(pool.feeReserveOf(address(wbtc)), 1075);
    assertEq(pool.reservedOf(address(wbtc)), 0.001 * 10**8);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 33.09 * 10**30);
    assertEq(pool.liquidityOf(address(wbtc)), 0.00257046 * 10**8);
    assertEq(wbtc.balanceOf(BOB), 16878);

    checkPoolBalanceWithState(address(wbtc), 1);
  }

  function testCorrectness_WhenLong_Aum() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    maticPriceFeed.setLatestAnswer(500 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);

    // Add 10 MATIC as a liquidity
    matic.mint(address(pool), 10 * 10**18);
    pool.addLiquidity(address(this), address(matic), ALICE);

    // The following conditions must be met:
    // 1. Pool's AUM by min price shoud be:
    // = (10 * (1-0.003)) * 500 = 4985 USD
    // 2. Pool's AUM by max price should be:
    // = (10 * (1-0.003)) * 500 = 4985 USD
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 4985 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 4985 * 10**18);

    // Long MATIC 2x with 1 MATIC (500 USD) as a collateral
    matic.mint(address(pool), 1 * 10**18);
    pool.increasePosition(
      address(this),
      0,
      address(matic),
      address(matic),
      1000 * 10**30,
      Exposure.LONG
    );

    // The following conditions must be met:
    // 1. Pool's MATIC liquidity should be:
    // = 9.97 + 1 - (1000 * 0.001 / 500)
    // = 10.968 MATIC
    // 2. Pool's MATIC reserved should be:
    // = 1000 / 500 = 2 MATIC
    // 3. Pool's guaranteed USD of MATIC should be:
    // = 1000 + (1000 * 0.001) - (500 * 1)
    // = 501 USD
    // 4. Pool's AUM by min price shoud be:
    // = 501 + ((10.968 - 2) * 500)
    assertEq(pool.liquidityOf(address(matic)), 10.968 * 10**18);
    assertEq(pool.reservedOf(address(matic)), 2 * 10**18);
    assertEq(pool.guaranteedUsdOf(address(matic)), 501 * 10**30);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 4985 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 4985 * 10**18);

    // MATIC pump to 750 USD
    maticPriceFeed.setLatestAnswer(750 * 10**8);
    maticPriceFeed.setLatestAnswer(750 * 10**8);
    maticPriceFeed.setLatestAnswer(750 * 10**8);

    // The following conditions must be met:
    // 1. Pool's AUM by min price shoud be:
    // = 501 + ((10.968 - 2) * 750)
    // = 7227 USD
    // 2. Pool's AUM by max price should be:
    // = 501 + ((10.968 - 2) * 750)
    // = 7227 USD
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 7227 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 7227 * 10**18);

    // Decrease position size 500 USD
    pool.decreasePosition(
      address(this),
      0,
      address(matic),
      address(matic),
      0,
      500 * 10**30,
      Exposure.LONG,
      address(this)
    );

    assertEq(
      pool.poolMath().getAum18(pool, MinMax.MIN),
      7227000000000000000250
    );
    assertEq(
      pool.poolMath().getAum18(pool, MinMax.MAX),
      7227000000000000000250
    );

    pool.decreasePosition(
      address(this),
      0,
      address(matic),
      address(matic),
      250 * 10**30,
      100 * 10**30,
      Exposure.LONG,
      address(this)
    );

    assertEq(
      pool.poolMath().getAum18(pool, MinMax.MIN),
      7227000000000000000250
    );
    assertEq(
      pool.poolMath().getAum18(pool, MinMax.MAX),
      7227000000000000000250
    );
  }

  function testCorrectness_WhenLong_MinProfitBps() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);

    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    // Add 0.0025 WBTC as a liquidity
    wbtc.mint(address(pool), 0.0025 * 10**8);
    pool.addLiquidity(address(this), address(wbtc), address(this));

    // Increase long position
    wbtc.mint(address(pool), 0.00025 * 10**8);
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      90 * 10**30,
      Exposure.LONG
    );

    wbtcPriceFeed.setLatestAnswer((41_000 - 1) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 - 1) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 - 1) * 10**8);

    (bool isProfit, uint256 delta) = pool.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(!isProfit);
    assertEq(delta, 2195121951219512195121951219);

    wbtcPriceFeed.setLatestAnswer((41_000 + 307) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 + 307) * 10**8);
    wbtcPriceFeed.setLatestAnswer((41_000 + 307) * 10**8);

    (isProfit, delta) = pool.getPositionDelta(
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(isProfit);
    assertEq(delta, 0);

    vm.warp(10 * 60 + 10);

    (isProfit, delta) = pool.getPositionDelta(
      address(this),
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(isProfit);
    assertEq(delta, 673902439024390243902439024390);
  }

  function testCorrectness_WhenLong_WhenLoss() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);

    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    // Add Liquidity
    wbtc.mint(address(pool), 0.0025 * 10**8);
    pool.addLiquidity(address(this), address(wbtc), address(this));

    // The following condition must be met:
    // 1. Pool's WBTC liquidity should be:
    // = 0.0025 * (1-0.003) = 0.0024925
    // 2. Pool should make:
    // = 0.0025 * 0.003 = 750 sathoshi
    // 3. Pool's AUM by min price should be:
    // = 0.0024925 * 40000 = 99.7 USD
    // 4. Pool's AUM by max price should be:
    // = 0.0024925 * 41000 = 102.1925 USD
    assertEq(pool.liquidityOf(address(wbtc)), 0.0024925 * 10**8);
    assertEq(pool.feeReserveOf(address(wbtc)), 750);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99.7 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 102.1925 * 10**18);

    // Increase long position
    wbtc.mint(address(pool), 0.00025 * 10**8);
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      90 * 10**30,
      Exposure.LONG
    );

    // The following condition must be met:
    // 1. Pool's WBTC liquidity should be:
    // = 0.0024925 + 0.00025 - ((90*0.001) / 41000)
    // = 0.00274031 WBTC
    // 2. Pool should make:
    // = 750 + 219
    // = 969 sathoshi
    // 3. Pool's guarantee WBTC should be:
    // = 90 + (90*0.001) - (0.00025 * 40000)
    // = 80.09 USD
    assertEq(pool.liquidityOf(address(wbtc)), 0.00274031 * 10**8);
    assertEq(pool.feeReserveOf(address(wbtc)), 969);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 80.09 * 10**30);

    // Assert position:
    // 1. Position's size should be 90 USD
    // 2. Position's collateral should be:
    // = (0.00025 * 40000) - (90 * 0.001) = 9.91 USD
    // 3. Position's average price should be:
    // = 41000 USD
    // 4. Position's entry funding rate should be: 0
    // 5. Position's reserved amount should be:
    // = 90 / 40000 = 0.00225 WBTC
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
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 0.00225 * 10**8);

    // WBTC price dropped
    wbtcPriceFeed.setLatestAnswer(40_790 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_690 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_590 * 10**8);

    // Assert position delta after price changed:
    // 1. Position's delta should be:
    // = 90 * (41000 - 40590) / 41000
    // = 0.9 USD
    // 2. WBTC price below the position's average price
    // Hence, position should be in loss
    (bool isProfit, uint256 delta) = pool.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(!isProfit);
    assertEq(delta, 0.9 * 10**30);

    // Position is in loss, then decrease position by 50 USD
    pool.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      0,
      50 * 10**30,
      Exposure.LONG,
      address(this)
    );

    // The following condition must be met:
    // 1. Pool's liquidity should be:
    // = 0.00274031 - (50 * 0.001 / 40790)
    // = 0.00273909
    // 2. Pool should make:
    // = 969 + 122 = 1091 sathoshi
    // 3. Pool's guarantee WBTC should be:
    // = 80.09 + (9.91 - (9.91 - ((0.9 * 50 / 90)) - (50 * 0.001))) - 50
    // = 30.64 USD
    assertEq(pool.liquidityOf(address(wbtc)), 0.00273909 * 10**8);
    assertEq(pool.feeReserveOf(address(wbtc)), 1091);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 30.64 * 10**30);

    // Assert position
    // 1. Position's size should be 40 USD
    // 2. Position's collateral should be:
    // = (9.91 - ((0.9 * 50 / 90)) - (50 * 0.001))
    // = 9.36 USD
    // 3. Position's average price should be: 41,000
    // 4. Position's entry funding rate: 0
    // 5. Position's reserve amount should be:
    // 0.00225 - (0.00225 * 50 / 90) = 0.001 WBTC
    // 6. Position's PnL should be:
    // = (90 * ((40590 - 41000) / 41000)) * 50 / 90
    // = 0.5 USD
    // 7. Position should not profitable.
    position = pool.getPosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(position.size, 40 * 10**30);
    assertEq(position.collateral, 9.36 * 10**30);
    assertEq(position.averagePrice, 41000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 0.001 * 10**8);
    assertEq(position.realizedPnl, 0.5 * 10**30);
    assertTrue(!position.hasProfit);

    // Close position completely
    pool.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      0,
      40 * 10**30,
      Exposure.LONG,
      address(this)
    );

    // The following conditions must be met:
    // 1. Pool's liquidity should be:
    // = 0.00273909 - (40 * 0.001 / 40790) - ((9.36 - 0.4 [loss] - 0.04 [margin fee]) / 40790)
    // = 0.00251943
    // 2. Pool should make:
    // = 1091 + 98 = 1189 sathoshi
    // 3. Pool's WBTC reserve should be 0
    // 4. Pool's guarantreed USD should be 0
    // 5. adddress(this) should received:
    // = ((9.36 - 0.4 [loss] - 0.04 [margin fee]) / 40790)
    // = 0.00021868
    assertEq(pool.liquidityOf(address(wbtc)), 0.00251943 * 10**8);
    assertEq(pool.feeReserveOf(address(wbtc)), 1189);
    assertEq(pool.reservedOf(address(wbtc)), 0);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 0);
    assertEq(wbtc.balanceOf(address(this)), 0.00021868 * 10**8);

    // Assert position
    // 1. Position's size should be 0 USD
    // 2. Position's collateral should be: 0 USD
    // 3. Position's average price should be: 0
    // 4. Position's entry funding rate: 0
    // 5. Position's reserve amount should be: 0
    position = pool.getPosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(position.size, 0);
    assertEq(position.collateral, 0);
    assertEq(position.averagePrice, 0);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 0);
  }
}
