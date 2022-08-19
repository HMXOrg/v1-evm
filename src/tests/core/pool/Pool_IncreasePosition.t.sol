// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Pool_BaseTest, console, Pool, PoolConfig } from "./Pool_BaseTest.t.sol";

contract Pool_IncreasePositionTest is Pool_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory tokenConfigs
    ) = buildDefaultSetTokenConfigInput();

    poolConfig.setTokenConfigs(tokens, tokenConfigs);
  }

  function testRevert_WhenMsgSenderNotAllowed() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_Forbidden()"));
    pool.increasePosition(
      ALICE,
      0,
      address(wbtc),
      address(wbtc),
      0,
      Exposure.LONG
    );
  }

  function testRevert_WhenLeverageDisabled() external {
    poolConfig.setIsLeverageEnable(false);

    vm.expectRevert(abi.encodeWithSignature("Pool_LeverageDisabled()"));
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      0,
      Exposure.LONG
    );
  }

  function testRevert_WhenCollateralTooSmallForFee() external {
    wbtcPriceFeed.setLatestAnswer(50000 * 10**8);

    vm.expectRevert(abi.encodeWithSignature("Pool_CollateralTooSmall()"));
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      1000 * 10**30,
      Exposure.LONG
    );
  }

  function testRevert_WhenPositionSizeInvalid() external {
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(50000 * 10**8);

    vm.expectRevert(abi.encodeWithSignature("Pool_BadPositionSize()"));
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      0,
      Exposure.LONG
    );
  }

  function testRevert_WhenLossesExceedCollateral() external {
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(50000 * 10**8);

    wbtc.mint(address(pool), 2500);

    vm.expectRevert(
      abi.encodeWithSignature("PoolMath_LossesExceedCollateral()")
    );
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      1000 * 10**30,
      Exposure.LONG
    );
  }

  function testRevert_WhenLiquidationFeeExceedCollateral() external {
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    wbtc.mint(address(pool), 12500);

    vm.expectRevert(
      abi.encodeWithSignature("PoolMath_LiquidationFeeExceedCollateral()")
    );
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      1000 * 10**30,
      Exposure.LONG
    );
  }

  function testRevert_WhenMaxLeverageExceed() external {
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    wbtc.mint(address(pool), 22500);

    // Max leverage is 88x
    // We use 22500 sathoshi = 22500 / 1e8 * 40000 = 9 USD as a collateral
    // Long position size at 9 * 88 = 792 USD should be reverted as max leverage is exceeded
    vm.expectRevert(abi.encodeWithSignature("PoolMath_MaxLeverageExceed()"));
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      792 * 10**30,
      Exposure.LONG
    );
  }

  function testRevert_WhenSizeMoreThanCollateral() external {
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    wbtc.mint(address(pool), 22500);

    vm.expectRevert(
      abi.encodeWithSignature("Pool_SizeSmallerThanCollateral()")
    );
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      8 * 10**30,
      Exposure.LONG
    );
  }

  function testRevert_WhenNotEnoughLiquidity() external {
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    wbtc.mint(address(pool), 22500);

    vm.expectRevert(abi.encodeWithSignature("Pool_InsufficientLiquidity()"));
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      500 * 10**30,
      Exposure.LONG
    );
  }

  function testRevert_WhenLong_WhenMisMatchToken() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_TokenMisMatch()"));
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(matic),
      0,
      Exposure.LONG
    );
  }

  function testRevert_WhenLong_WhenCollateralIsStable() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_CollateralTokenIsStable()"));
    pool.increasePosition(
      address(this),
      0,
      address(dai),
      address(dai),
      0,
      Exposure.LONG
    );
  }

  function testRevert_WhenLong_WhenCollateralTokenNotAllow() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_BadToken()"));
    pool.increasePosition(
      address(this),
      0,
      address(randomErc20),
      address(randomErc20),
      0,
      Exposure.LONG
    );
  }

  function testCorrectness_WhenLong_WhenIncreasePosition() external {
    maticPriceFeed.setLatestAnswer(400 * 10**8);
    daiPriceFeed.setLatestAnswer(1 * 10**8);

    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    wbtc.mint(ALICE, 1 * 10**8);

    // ----- Start Alice session -----
    vm.startPrank(ALICE);

    // Alice add liquidity with 117499 satoshi
    wbtc.transfer(address(pool), 117499);
    pool.addLiquidity(ALICE, address(wbtc), ALICE);

    // After Alice added 117499 satoshi as a liquidity,
    // the following conditions should be met:
    // 1. Alice should get 46.8584 PLP
    // 2. Pool should make 353 sathoshi
    // 3. Pool's AUM by min price should be:
    // 0.00117499 * (1-0.003) * 40000 = 46.8584 USD
    // 4. Pool's AUM by max price should be:
    // 0.00117499 * (1-0.003) * 41000 = 48.02986 USD
    // 5. WBTC's USD debt should be 48.8584 USD
    // 6. WBTC's liquidity should be 117499 - 353 = 117146 satoshi
    // 7. Redeemable WBTC in USD should be 48.8584 USD
    assertEq(pool.plp().balanceOf(ALICE), 46.8584 * 10**18);
    assertEq(pool.feeReserveOf(address(wbtc)), 353);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 46.8584 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 48.02986 * 10**18);
    assertEq(pool.usdDebtOf(address(wbtc)), 46.8584 * 10**18);
    assertEq(pool.liquidityOf(address(wbtc)), 117146);
    assertEq(pool.getRedemptionCollateralUsd(address(wbtc)), 46.8584 * 10**30);

    // Alice add liquidity again with 117499 satoshi
    wbtc.transfer(address(pool), 117499);
    pool.addLiquidity(ALICE, address(wbtc), ALICE);

    // After Alice added 117499 satoshi as a liquidity,
    // the following conditions should be met:
    // 1. Alice should get 46.8584 + (46.8584 * 46.8584 / 48.02986) = 92573912195121951219 PLP
    // 2. Pool should make 706 sathoshi
    // 3. Pool's AUM by min price should be:
    // 46.8584 + (0.00117499 * (1-0.003) * 40000) = 93.7168 USD
    // 4. Pool's AUM by max price should be:
    // 48.02986 + (0.00117499 * (1-0.003) * 41000) = 96.05972 USD
    // 5. WBTC's USD debt should be 93.7168 USD
    // 6. WBTC's liquidity should be 117146 + 117499 - 353 = 234292 satoshi
    // 7. Redeemable WBTC in USD should be 93.7168 USD
    assertEq(pool.plp().balanceOf(ALICE), 92573912195121951219);
    assertEq(pool.feeReserveOf(address(wbtc)), 706);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 93.7168 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 96.05972 * 10**18);
    assertEq(pool.usdDebtOf(address(wbtc)), 93.7168 * 10**18);
    assertEq(pool.liquidityOf(address(wbtc)), 234292);
    assertEq(pool.getRedemptionCollateralUsd(address(wbtc)), 93.7168 * 10**30);

    // Alice increase long position with sub account id = 0
    wbtc.transfer(address(pool), 22500);
    pool.increasePosition(
      ALICE,
      0,
      address(wbtc),
      address(wbtc),
      47 * 10**30,
      Exposure.LONG
    );

    // The following condition expected to be happened:
    // 1. Pool's WBTC liquidity should be:
    // = 234292 + 22500 - (((47 * 0.001) + (47 * 0)) / 41000)
    // = 234292 + 22500 - 114 = 256678 sathoshi
    // 2. Pool's WBTC reserved should be:
    // = 47 / 40000 = 117500 sathoshi
    // 3. Pool's WBTC guarantee USD should be:
    // = 47 + 0.0047 - ((22500 / 1e8) * 40000) = 38.047 USD
    // 4. Redeemable WBTC in USD should be:
    // = ((256678 + 92797 - 117500) / 1e8) * 40000 = 92.79 USD
    // 5. Pool's AUM by min price should be:
    // 38.047 + ((256678 - 117500) / 1e8) * 40000 = 93.7182 USD
    // 6. Pool's AUM by max price should be:
    // 38.047 + ((256678 - 117500) / 1e8) * 41000 = 95.10998 USD
    // 7. Pool should makes 706 + 114 = 820 sathoshi
    // 8. Pool's WBTC USD debt should still the same as before
    // 9. Pool's WBTC balance should be:
    // = 256678 + 820 = 257498 sathoshi
    assertEq(pool.liquidityOf(address(wbtc)), 256678);
    assertEq(pool.reservedOf(address(wbtc)), 117500);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 38.047 * 10**30);
    assertEq(pool.getRedemptionCollateralUsd(address(wbtc)), 92.79 * 10**30);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 93.7182 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 95.10998 * 10**18);
    assertEq(pool.feeReserveOf(address(wbtc)), 820);
    assertEq(pool.usdDebtOf(address(wbtc)), 93.7168 * 10**18);
    assertEq(wbtc.balanceOf(address(pool)), 257498);

    // Assert a postion
    // 1. Position's size should be 47 USD
    // 2. Position's collateral should be:
    // = ((22500 / 1e8) * 40000) - 0.047 = 8.953 USD
    // 3. Position's average price should be 41000 USD
    Pool.GetPositionReturnVars memory position = pool.getPosition(
      ALICE,
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(position.size, 47 * 10**30);
    assertEq(position.collateral, 8.953 * 10**30);
    assertEq(position.averagePrice, 41000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 117500);
    assertEq(position.realizedPnl, 0);
    assertTrue(position.hasProfit == true);
    assertEq(position.lastIncreasedTime, block.timestamp);

    vm.stopPrank();
    // ----- Stop Alice session ------
  }

  function testCorretness_WhenLong_WhenPriceChanges_WhenIncreasePosition()
    external
  {
    daiPriceFeed.setLatestAnswer(1 * 10**18);
    maticPriceFeed.setLatestAnswer(300 * 10**18);

    wbtcPriceFeed.setLatestAnswer(100_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(100_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(100_000 * 10**8);

    // Add 1 WBTC as a liquidity for the pool
    wbtc.mint(address(pool), 1 * 10**8);
    pool.addLiquidity(address(this), address(wbtc), address(this));

    // The following criteria should be met:
    // 1. address(this) should get 1 * (1-0.003) * 100000 = 99700 PLP
    // 2. Pool's WBTC liquidity should be:
    // = 1 * (1-0.003) = 0.997 WBTC
    // 3. Pool should make 0.003 WBTC as fee reserve
    // 4. Pool's WBTC USD debt should be:
    // = 1 * (1-0.003) * 100000 = 99700 USD
    // 5. Pool's AUM with min price should be:
    // = 0.997 * 100000 = 99700 USD
    // 6. Pool's AUM with max price should be:
    // = 0.997 * 100000 = 99700 USD
    assertEq(pool.plp().balanceOf(address(this)), 99700 * 10**18);
    assertEq(pool.liquidityOf(address(wbtc)), 0.997 * 10**8);
    assertEq(pool.feeReserveOf(address(wbtc)), 0.003 * 10**8);
    assertEq(pool.usdDebtOf(address(wbtc)), 99700 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99700 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 99700 * 10**18);

    // Long 80,000 USD on WBTC with 0.5 WBTC (50,000 USD) as a collateral
    // This is 80,000 / 50,000 = 1.6x
    wbtc.mint(address(pool), 0.5 * 10**8);
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      80_000 * 10**30,
      Exposure.LONG
    );

    // The following conditions need to be met after long position created:
    // 1. Pool's liquidity should be:
    // = 0.997 + 0.5 - (((80000 * 0.001) + (0.5 * 0)) / 100000)
    // = 0.997 + 0.5 - 0.0008 = 1.4962 WBTC
    // 2. Pool's WBTC reserved should be:
    // = 80000 / 100000 = 0.8 WBTC
    // 3. Pool's WBTC guarantee USD should be:
    // = 80000 + 80 - (0.5 * 100000) = 30080 USD
    // 4. Redemptable WBTC in USD should be:
    // = 30080 + ((1.4962 - 0.8) * 100000) = 99700 USD
    // 5. Pool's AUM by min price should be:
    // = 30080 + ((1.4962 - 0.8) * 100000) = 99700 USD
    // 6. Pool's AUM by max price should be:
    // = 30080 + ((1.4962 - 0.8) * 100000) = 99700 USD
    // 7. Pool should makes 0.003 + 0.0008 = 0.0038 WBTC as fee reserve
    assertEq(pool.liquidityOf(address(wbtc)), 1.4962 * 10**8);
    assertEq(pool.reservedOf(address(wbtc)), 0.8 * 10**8);
    assertEq(pool.guaranteedUsdOf(address(wbtc)), 30080 * 10**30);
    assertEq(pool.getRedemptionCollateralUsd(address(wbtc)), 99700 * 10**30);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99700 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 99700 * 10**18);
    assertEq(pool.feeReserveOf(address(wbtc)), 0.0038 * 10**8);

    // Assert position
    // 1. Position's size should be 80 USD
    // 2. Position's collateral should be:
    // = (0.5 - 0.0008) * 100000 = 49920 USD
    // 3. Position's average price should be 100000 USD
    // 4. Position's entry funding rate should be 0
    // 5. Position's reserve amount should be 0.8 WBTC
    // 6. Position's realized pnl should be 0
    // 7. Position's has profit should be true
    // 8. Position's last increased time should be block.timestamp
    Pool.GetPositionReturnVars memory position = pool.getPosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertEq(position.size, 80_000 * 10**30);
    assertEq(position.collateral, 49920 * 10**30);
    assertEq(position.averagePrice, 100000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 0.8 * 10**8);
    assertEq(position.realizedPnl, 0);
    assertTrue(position.hasProfit == true);
    assertEq(position.lastIncreasedTime, block.timestamp);

    // WBTC price pump to 150,000 USD
    wbtcPriceFeed.setLatestAnswer(150_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(150_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(150_000 * 10**8);

    // The following conditions should be met:
    // 1. The position should be profitable
    // 2. The position's delta should be 0.8 * 150000 - 80000 = 40000 USD
    // 3. Pool's AUM by min price should be:
    // = 30080 + ((1.4962 - 0.8) * 150000) = 134510 USD
    // 4. Pool's AUM by max price should be:
    // = 30080 + ((1.4962 - 0.8) * 150000) = 134510 USD
    (bool isProfit, uint256 delta) = pool.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      Exposure.LONG
    );
    assertTrue(isProfit);
    assertEq(delta, 40000 * 10**30);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 134510 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 134510 * 10**18);

    // WBTC dump to 50,000 - 75,000 USD
    wbtcPriceFeed.setLatestAnswer(50_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(50_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(75_000 * 10**8);

    // The following conditions should be met:
    // 1. The position should be in loss
    // 2. The position's delta should be 0.8 * 50000 - 80000 = -40000 USD
    // 3. Pool's AUM by min price should be:
    // = 30080 + ((1.4962 - 0.8) * 50000) = 64890 USD
    // 4. Pool's AUM by max price should be:
    // = 30080 + ((1.4962 - 0.8) * 75000) = 82295 USD
    assertTrue(isProfit);
    assertEq(delta, 40000 * 10**30);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 64890 * 10**18);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 82295 * 10**18);
  }

  function testRevert_WhenShort_WhenCollateralNotStable() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_CollateralTokenNotStable()"));
    pool.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      1,
      Exposure.SHORT
    );
  }
}
