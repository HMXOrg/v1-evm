// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolDiamond_BaseTest, console, Pool, LibPoolConfigV1, LiquidityFacetInterface, GetterFacetInterface, PerpTradeFacetInterface } from "./PoolDiamond_BaseTest.t.sol";

contract PoolDiamond_FundingRateTest is PoolDiamond_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens2,
      LibPoolConfigV1.TokenConfig[] memory tokenConfigs2
    ) = buildDefaultSetTokenConfigInput2();

    poolAdminFacet.setTokenConfigs(tokens2, tokenConfigs2);
  }

  function testCorrectness_BorrowingRate() external {
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
    wbtc.mint(address(poolDiamond), 0.0025 * 10**8);
    poolLiquidityFacet.addLiquidity(
      address(this),
      address(wbtc),
      address(this)
    );

    // The following conditions need to be met:
    // 1. Pool's AUM by min price should be:
    // 0.0025 * (1-0.003) * 40000 = 99.7 USD
    // 2. Pool's AUM by max price should be:
    // 0.0025 * (1-0.003) * 41000 = 102.1925 USD
    assertEq(poolGetterFacet.getAumE18(false), 99.7 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 102.1925 * 10**18);

    // Increase long position with 0.00025 WBTC (=10 USD) as a collateral
    // With 9x leverage; Hence position's size should be 90 USD.
    wbtc.mint(address(poolDiamond), 0.00025 * 10**8);
    poolPerpTradeFacet.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      90 * 10**30,
      true
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
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.00274031 * 10**8);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(wbtc)), 80.09 * 10**30);
    assertEq(poolGetterFacet.reservedOf(address(wbtc)), 0.00225 * 10**8);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 969);
    assertEq(poolGetterFacet.getAumE18(false), 99.7024 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 100.19271 * 10**18);

    // Assert position
    // 1. Position's size should be 90 USD
    // 2. Position's collateral should be:
    // = (0.00025 * 40000) - (90 * 0.001) = 9.91 USD
    // 3. Position's average price should be: 41000 USD
    // 4. Position's entry funding rate should be: 0
    // 5. Position's reserve amount should be: 90 / 41000 = 0.00225 USD
    GetterFacetInterface.GetPositionReturnVars memory position = poolGetterFacet
      .getPositionWithSubAccountId(
        address(this),
        0,
        address(wbtc),
        address(wbtc),
        true
      );
    assertEq(position.size, 90 * 10**30);
    assertEq(position.collateral, 9.91 * 10**30);
    assertEq(position.averagePrice, 41000 * 10**30);
    assertEq(position.entryBorrowingRate, 0 * 10**30);
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
    (bool isProfit, uint256 delta, ) = poolGetterFacet.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      true
    );
    assertEq(delta, 9 * 10**30);
    assertTrue(isProfit);

    // Assert position's leverage
    assertEq(
      poolGetterFacet.getPositionLeverage(
        address(this),
        0,
        address(wbtc),
        address(wbtc),
        true
      ),
      90817
    );

    // Decrease position size 50 USD and collateral 3 USD
    poolPerpTradeFacet.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      3 * 10**30,
      50 * 10**30,
      true,
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
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 1075);
    assertEq(poolGetterFacet.reservedOf(address(wbtc)), 0.001 * 10**8);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(wbtc)), 33.09 * 10**30);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.00257046 * 10**8);
    assertEq(wbtc.balanceOf(BOB), 16878);

    // Assert position
    // 1. Position's size should be: 40 USD
    // 2. Position's collateral should be: 6.91 USD
    // 3. Position's average price should be: 41000 USD
    // 4. Position's entry funding rate should be: 0
    // 5. Position's reserve amount should be: 0.00225 * 40 / 90 = 0.001 WBTC
    // 6. Position's realized PnL should be: 5 USD
    // 7. Position should be profitable
    position = poolGetterFacet.getPositionWithSubAccountId(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      true
    );
    assertEq(position.size, 40 * 10**30);
    assertEq(position.collateral, 6.91 * 10**30);
    assertEq(position.averagePrice, 41000 * 10**30);
    assertEq(position.entryBorrowingRate, 0 * 10**30);
    assertEq(position.reserveAmount, 0.001 * 10**8);
    assertEq(position.realizedPnl, 5 * 10**30);
    assertTrue(position.hasProfit);

    // Assert position's leverage
    assertEq(
      poolGetterFacet.getPositionLeverage(
        address(this),
        0,
        address(wbtc),
        address(wbtc),
        true
      ),
      57887
    );

    // Warp to pass funding time interval
    vm.warp(block.timestamp + 8 hours + 1);

    // = 0.01% * 100000.0 / 257046.0 * 8
    // = 0.0311% --> Borrowing Rate
    assertEq(poolGetterFacet.getNextBorrowingRate(address(wbtc)), 311);

    (isProfit, delta, ) = poolGetterFacet.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      true
    );

    // Withdraw collateral so postion get charged by the funding fee
    poolPerpTradeFacet.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      1 * 10**30,
      0,
      true,
      BOB
    );

    // Assert pool state:
    // 1. Pool shoulud make:
    // = 1075 + funding fee
    // Where funding fee is:
    // = 0.01% * 100000.0 / 257046.0 * 8
    // = 0.0311% --> Borrowing Rate
    // = 40 * 0.0311%
    // = 0.01244 USD --> Borrowing Fee USD
    // = 0.01244 / 47100 * 1e8
    // = 26 sats
    // Hence; 1075 + 26 = 1101 sathoshi
    // 2. Pool's WBTC reserved should remind the same.
    // 3. Pool's guaranteed usd of WBTC should be:
    // = 33.09 + (6.91 - 5.91) = 34.09 USD
    // 4. Pool's WBTC liquidity should be:
    // = 257046 - ((1 [CollateralDelta]) / 47100 * 1e8)
    // = 257046 - 2123
    // = 254923 WBTC
    // 5. Bob's WBTC balance should be:
    // = 16878 + (1 [CollateralDelta] / 47100 * 1e8) - fundingFee
    // = 16878 + 2123 - 26 - 1 (offset)
    // = 18974 sathoshi
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 1101);
    assertEq(poolGetterFacet.reservedOf(address(wbtc)), 0.001 * 10**8);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(wbtc)), 34.09 * 10**30);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 254923);
    assertEq(wbtc.balanceOf(BOB), 18974);

    checkPoolBalanceWithState(address(wbtc), 2);
  }

  function testCorrectness_FundingRate_LongOnly() external {
    // Warp 8 hours so time not start with 0
    vm.warp(1662100761);

    // Initialized price feeds
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    // Assuming WBTC price is at 41,000 USD
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);

    // Add 10 WBTC as a liquidity of the pool
    wbtc.mint(address(poolDiamond), 10 * 10**8);
    poolLiquidityFacet.addLiquidity(
      address(this),
      address(wbtc),
      address(this)
    );

    dai.mint(address(poolDiamond), 1000000 ether);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // Increase long position with 1 WBTC (=40,000 USD) as a collateral
    // With 9x leverage; Hence position's size should be 360,000 USD.
    wbtc.mint(address(poolDiamond), 1 * 10**8);
    poolPerpTradeFacet.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      360_000 * 10**30,
      true
    );

    // Open Interest Long
    // = positionSize / wbtcPrice
    // = 360000 / 41000 = 8.7804878 WBTC
    // Open Interest Short
    // = 0 WBTC (No Short position yet)
    assertEq(
      poolGetterFacet.openInterestLong(address(wbtc)),
      8.7804878 * 10**8
    );
    assertEq(poolGetterFacet.openInterestShort(address(wbtc)), 0);

    // Checking the position delta right after opening the position
    (bool isProfit, uint256 delta, int256 fundingFee) = poolGetterFacet
      .getPositionDelta(address(this), 0, address(wbtc), address(wbtc), true);
    // Position should not have any delta or funding fee
    assertFalse(isProfit);
    assertEq(delta, 0);
    assertEq(fundingFee, 0);

    // warp 1 interval
    vm.warp(block.timestamp + 1 hours + 1);

    // Long Funding Rate
    // = (openInterestLong - openInterestShort) * intervals * fundingRateFactor / openInterestLong
    // = 8.7804878 * 1 * 25 / 8.7804878 = 25
    // Short Funding Rate
    // = (openInterestLong - openInterestShort) * intervals * fundingRateFactor * (-1) / openInterestShort
    // = 0
    (int256 fundingRateLong, int256 fundingRateShort) = poolGetterFacet
      .getNextFundingRate(address(wbtc));
    assertEq(fundingRateLong, 25);
    assertEq(fundingRateShort, 0);

    // Force update funding rate to make our position pay funding fee
    poolFundingRateFacet.updateFundingRate(address(wbtc), address(wbtc));
    (isProfit, delta, fundingFee) = poolGetterFacet.getPositionDelta(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      true
    );

    // No price movement, no profit
    assertFalse(isProfit);
    // Funding Fee
    // = positionSize * fundingRateLong / 1000000
    // = 360000 * 25 / 1000000 = 9 USD
    // (Delta only include funding fee here, cuz there is no delta from zero price movement)
    assertEq(delta, 9 * 10**30);
    assertEq(fundingFee, 9 * 10**30);
  }

  function testCorrectness_FundingRate_LongPayShort() external {
    // Warp 8 hours so time not start with 0
    vm.warp(1662100761);

    // Initialized price feeds
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    // Assuming WBTC price is at 41,000 USD
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);

    // Add 10 WBTC as a liquidity of the pool
    wbtc.mint(address(poolDiamond), 10 * 10**8);
    poolLiquidityFacet.addLiquidity(
      address(this),
      address(wbtc),
      address(this)
    );

    dai.mint(address(poolDiamond), 1000000 ether);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // Increase WBTC long position with 1 WBTC (=40,000 USD) as a collateral
    // With 9x leverage; Hence position's size should be 360,000 USD.
    wbtc.mint(address(poolDiamond), 1 * 10**8);
    poolPerpTradeFacet.increasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      360_000 * 10**30,
      true
    );

    // Increase WBTC short position with 10,000 DAI (=10,000 USD) as a collateral
    // With 18x leverage; Hence position's size should be 180,000 USD.
    dai.mint(address(poolDiamond), 10000 ether);
    poolPerpTradeFacet.increasePosition(
      address(this),
      0,
      address(dai),
      address(wbtc),
      180_000 * 10**30,
      false
    );

    // Open Interest Long
    // = positionSize / wbtcPrice
    // = 360000 / 41000 = 8.7804878 WBTC
    // Open Interest Short
    // = 180000 / 41000 = 4.3902439 WBTC
    assertEq(
      poolGetterFacet.openInterestLong(address(wbtc)),
      8.7804878 * 10**8
    );
    assertEq(
      poolGetterFacet.openInterestShort(address(wbtc)),
      4.3902439 * 10**8
    );

    // Checking the position delta right after opening the position
    // Position should not have any delta or funding fee
    (
      bool isProfitLong,
      uint256 deltaLong,
      int256 fundingFeeLong
    ) = poolGetterFacet.getPositionDelta(
        address(this),
        0,
        address(wbtc),
        address(wbtc),
        true
      );
    assertFalse(isProfitLong);
    assertEq(deltaLong, 0);
    assertEq(fundingFeeLong, 0);

    (
      bool isProfitShort,
      uint256 deltaShort,
      int256 fundingFeeShort
    ) = poolGetterFacet.getPositionDelta(
        address(this),
        0,
        address(dai),
        address(wbtc),
        false
      );
    assertFalse(isProfitShort);
    assertEq(deltaShort, 0);
    assertEq(fundingFeeShort, 0);

    uint256 aumBefore = poolGetterFacet.getAum(true);

    // warp 1 interval
    vm.warp(block.timestamp + 1 hours + 1);

    // Long Funding Rate
    // = (openInterestLong - openInterestShort) * intervals * fundingRateFactor / openInterestLong
    // = (8.7804878 - 4.3902439) * 1 * 25 / 8.7804878 = 12.5 ~= 13 (round up)
    // Short Funding Rate
    // = (openInterestLong - openInterestShort) * intervals * fundingRateFactor * (-1) / openInterestShort
    // = (8.7804878 - 4.3902439) * 1 * 25 * (-1) / 4.3902439 = -25
    (int256 fundingRateLong, int256 fundingRateShort) = poolGetterFacet
      .getNextFundingRate(address(wbtc));
    assertEq(fundingRateLong, 13);
    assertEq(fundingRateShort, -25);

    // Force update funding rate to make our position pay funding fee
    poolFundingRateFacet.updateFundingRate(address(wbtc), address(wbtc));

    (isProfitLong, deltaLong, fundingFeeLong) = poolGetterFacet
      .getPositionDelta(address(this), 0, address(wbtc), address(wbtc), true);
    (isProfitShort, deltaShort, fundingFeeShort) = poolGetterFacet
      .getPositionDelta(address(this), 0, address(dai), address(wbtc), false);

    // Long Position:
    // No price movement, no profit
    // Funding Fee
    // = positionSize * fundingRateLong / 1000000
    // = 360000 * 13 / 1000000 = 4.68 USD
    // (Delta only include funding fee here, cuz there is no delta from zero price movement)
    assertFalse(isProfitLong);
    assertEq(deltaLong, 4.68 * 10**30);
    assertEq(fundingFeeLong, 4.68 * 10**30);

    // Short Position:
    // No price movement, no profit
    // Funding Fee
    // = positionSize * fundingRateLong / 1000000
    // = 180000 * (-25) / 1000000 = -4.5 USD
    // (Delta only include funding fee here, cuz there is no delta from zero price movement)
    assertTrue(isProfitShort);
    assertEq(deltaShort, 4.5 * 10**30);
    assertEq(fundingFeeShort, -4.5 * 10**30);

    // No change in PLP AUM as there is no realized positions
    assertEq(aumBefore, poolGetterFacet.getAum(true));

    // Close Long position entirely
    poolPerpTradeFacet.decreasePosition(
      address(this),
      0,
      address(wbtc),
      address(wbtc),
      0,
      360_000 * 10**30,
      true,
      address(this)
    );

    (uint256 fundingFeePayable, uint256 fundingFeeReceivable) = poolGetterFacet
      .getFundingFeeAccounting();

    assertEq(aumBefore, poolGetterFacet.getAum(true));
    assertEq(fundingFeePayable, 4.68 * 10**30);
    assertEq(fundingFeeReceivable, 0);
  }
}
