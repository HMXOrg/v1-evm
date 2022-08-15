// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Pool_BaseTest, PoolConfig, Pool, console } from "./Pool_BaseTest.t.sol";

contract Pool_AddLiquidity is Pool_BaseTest {
  function setUp() public override {
    super.setUp();

    address[] memory tokens = new address[](3);
    tokens[0] = address(dai);
    tokens[1] = address(wbtc);
    tokens[2] = address(matic);

    PoolConfig.TokenConfig[] memory tokenConfigs = new PoolConfig.TokenConfig[](
      3
    );
    tokenConfigs[0] = PoolConfig.TokenConfig({
      accept: true,
      isStable: true,
      isShortable: false,
      decimals: dai.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0
    });
    tokenConfigs[1] = PoolConfig.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: wbtc.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0
    });
    tokenConfigs[2] = PoolConfig.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: matic.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0
    });

    poolConfig.setTokenConfigs(tokens, tokenConfigs);

    // Feed prices
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
  }

  function testCorrectness_WhenDynamicFeeOff() external {
    // Mint 100 DAI to Alice
    dai.mint(ALICE, 100 ether);

    // ------- Alice session -------
    // Alice as a liquidity provider for DAI
    vm.startPrank(ALICE);
    dai.approve(address(pool), type(uint256).max);

    // Perform add liquidity
    pool.addLiquidity(address(dai), 100 ether, ALICE, 99 ether);

    // After Alice added DAI liquidity, the following criteria needs to satisfy:
    // 1. DAI balance of Alice should be 0
    // 2. DAI balance of Pool should be 100
    // 3. Due to no liquidity being added before, then PLP should be the same as the USD of DAI
    // Hence, Alice should get 100 * (1-0.003) = 99.7 PLP.
    // 4. Total supply of PLP should be 99.7 PLP
    // 5. Alice's lastAddLiquidityAt should be the current block timestamp
    // 6. Pool's AUM at Max price should be 99.7 USD
    // 7. Pool's AUM at Min price should be 99.7 USD
    // 8. Pool's total USD debt should be 99.7 USD
    assertEq(dai.balanceOf(ALICE), 0);
    assertEq(dai.balanceOf(address(pool)), 100 ether);
    assertEq(pool.plp().balanceOf(ALICE), 99.7 ether);
    assertEq(pool.plp().totalSupply(), 99.7 ether);
    assertEq(pool.lastAddLiquidityAtOf(ALICE), block.timestamp);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 99.7 ether);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99.7 ether);
    assertEq(pool.totalUsdDebt(), 99.7 ether);

    vm.stopPrank();
    // ------- Finish Alice session -------

    matic.mint(BOB, 1 ether);
    vm.warp(block.timestamp + 1 days);

    // Feed MATIC price
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    // ------- Bob session -------
    vm.startPrank(BOB);
    matic.approve(address(pool), type(uint256).max);

    // Perform add liquidity
    pool.addLiquidity(address(matic), 1 ether, BOB, 297.6 ether);

    // After Bob added MATIC liquidity, the following criteria needs to satisfy:
    // 1. MATIC balance of Bob should be 0
    // 2. MATIC balance of Pool should be 1
    // 3. Dynamic Fee Off, static 30 BPS fee applied. Hence, Bob should get 300 * (1-0.003) = 299.1 PLP.
    // 4. Total supply of PLP should be 99.7 + 299.1 = 398.8 PLP
    // 5. Bob's lastAddLiquidityAt should be the current block timestamp
    // 6. Pool's AUM at Max price should be 99.7 USD + (1 * (1-0.003) * 400) USD = 498.5 USD
    // 7. Pool's AUM at Min price should be 99.7 USD + (1 * (1-0.003) * 300) USD = 398.8 USD
    // 8. Pool's totalUsdDebt = 99.7 + (1 * (1-0.003) * 300) = 398.8 USD
    assertEq(matic.balanceOf(BOB), 0);
    assertEq(matic.balanceOf(address(pool)), 1 ether);
    assertEq(pool.plp().balanceOf(BOB), 299.1 ether);
    assertEq(pool.plp().totalSupply(), 398.8 ether);
    assertEq(pool.lastAddLiquidityAtOf(BOB), block.timestamp);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 498.5 ether);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 398.8 ether);
    assertEq(pool.totalUsdDebt(), 398.8 ether);

    vm.stopPrank();
    // ------- Finish Bob session -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 598.2 ether);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 498.5 ether);

    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    // Mint 0.01 WBTC (600 USD) to CAT.
    wbtc.mint(CAT, 1000000);
    vm.warp(block.timestamp + 1 days);

    // ------- Cat session -------
    vm.startPrank(CAT);
    wbtc.approve(address(pool), type(uint256).max);

    // Perform add liquidity
    pool.addLiquidity(address(wbtc), 1000000, CAT, 396 ether);

    // After Cat added WBTC liquidity, the following criteria needs to satisfy:
    // 1. WBTC balance of Cat should be 0
    // 2. WBTC balance of Pool should be 0.01 WBTC
    // 3. Dynamic fee is off, static 30 bps mint fee applied. Hence,
    // Cat should get (0.01 * (1-0.003) * 60000) * 398.8 / 598.2 = 398.8 PLP.
    // 4. Total supply of PLP should be 397.3 + 398.8 = 797.6 PLP
    // 5. Cat's lastAddLiquidityAt should be the current block timestamp
    // 6. Pool's AUM at Max price should be 99.7 + (1 * (1-0.003) * 500) + (0.01 * (1-0.003) * 60000) USD = 1196.4 USD
    // 7. Pool's AUM at Min price should be 99.7 + (1 * (1-0.003) * 400) + (0.01 * (1-0.003) * 60000) USD = 1096.7 USD
    // 8. Pool's totalUsdDebt = 99.7 + (1 * (1-0.003) * 300) + (0.01 * (1-0.003) * 60000) = 997 USD
    assertEq(wbtc.balanceOf(CAT), 0);
    assertEq(wbtc.balanceOf(address(pool)), 1000000);
    assertEq(pool.plp().balanceOf(CAT), 398.8 ether);
    assertEq(pool.plp().totalSupply(), 797.6 ether);
    assertEq(pool.lastAddLiquidityAtOf(CAT), block.timestamp);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 1196.4 ether);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 1096.7 ether);
    assertEq(pool.totalUsdDebt(), 997 ether);
  }

  function testCorrectness_WhenDynamicFeeOn() external {
    // Enable dynamic fee
    poolConfig.setIsDynamicFeeEnable(true);

    // Mint 100 DAI to Alice
    dai.mint(ALICE, 100 ether);

    // ------- Alice session -------
    // Alice as a liquidity provider for DAI
    vm.startPrank(ALICE);
    dai.approve(address(pool), type(uint256).max);

    // Perform add liquidity
    pool.addLiquidity(address(dai), 100 ether, ALICE, 99 ether);

    // After Alice added DAI liquidity, the following criteria needs to satisfy:
    // 1. DAI balance of Alice should be 0
    // 2. DAI balance of Pool should be 100
    // 3. Due to no liquidity being added before, then PLP should be the same as the USD of DAI
    // Hence, Alice should get 100 * (1-0.003) = 99.7 PLP.
    // 4. Total supply of PLP should be 99.7 PLP
    // 5. Alice's lastAddLiquidityAt should be the current block timestamp
    // 6. Pool's AUM at Max price should be 99.7 USD
    // 7. Pool's AUM at Min price should be 99.7 USD
    // 8. Pool's total USD debt should be 99.7 USD
    assertEq(dai.balanceOf(ALICE), 0);
    assertEq(dai.balanceOf(address(pool)), 100 ether);
    assertEq(pool.plp().balanceOf(ALICE), 99.7 ether);
    assertEq(pool.plp().totalSupply(), 99.7 ether);
    assertEq(pool.lastAddLiquidityAtOf(ALICE), block.timestamp);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 99.7 ether);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 99.7 ether);
    assertEq(pool.totalUsdDebt(), 99.7 ether);

    vm.stopPrank();
    // ------- Finish Alice session -------

    matic.mint(BOB, 1 ether);
    vm.warp(block.timestamp + 1 days);

    // Feed MATIC price
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    // ------- Bob session -------
    vm.startPrank(BOB);
    matic.approve(address(pool), type(uint256).max);

    // Perform add liquidity
    pool.addLiquidity(address(matic), 1 ether, BOB, 297.6 ether);

    // After Bob added MATIC liquidity, the following criteria needs to satisfy:
    // 1. MATIC balance of Bob should be 0
    // 2. MATIC balance of Pool should be 1
    // 3. Due to there is some liquidity in the pool, then the mint fee bps will be dynamic
    // according to the equation, mint fee is 80 bps. Hence, Bob should get 300 * (1-0.008) = 297.6 PLP.
    // 4. Total supply of PLP should be 99.7 + 297.6 = 397.3 PLP
    // 5. Bob's lastAddLiquidityAt should be the current block timestamp
    // 6. Pool's AUM at Max price should be 99.7 USD + (1 * (1-0.008) * 400) USD = 496.5 USD
    // 7. Pool's AUM at Min price should be 99.7 USD + (1 * (1-0.008) * 300) USD = 397.3 USD
    // 8. Pool's totalUsdDebt = 99.7 + (1 * (1-0.008) * 300) = 397.3 USD
    assertEq(matic.balanceOf(BOB), 0);
    assertEq(matic.balanceOf(address(pool)), 1 ether);
    assertEq(pool.plp().balanceOf(BOB), 297.6 ether);
    assertEq(pool.plp().totalSupply(), 397.3 ether);
    assertEq(pool.lastAddLiquidityAtOf(BOB), block.timestamp);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 496.5 ether);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 397.3 ether);
    assertEq(pool.totalUsdDebt(), 397.3 ether);

    vm.stopPrank();
    // ------- Finish Bob session -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 595.7 ether);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 496.5 ether);

    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    // Mint 0.01 WBTC (600 USD) to CAT.
    wbtc.mint(CAT, 1000000);
    vm.warp(block.timestamp + 1 days);

    // ------- Cat session -------
    vm.startPrank(CAT);
    wbtc.approve(address(pool), type(uint256).max);

    // Perform add liquidity
    pool.addLiquidity(address(wbtc), 1000000, CAT, 396 ether);

    // After Cat added WBTC liquidity, the following criteria needs to satisfy:
    // 1. WBTC balance of Cat should be 0
    // 2. WBTC balance of Pool should be 0.01 WBTC
    // 3. Due to there is some liquidity in the pool, then the mint fee bps will be dynamic
    // according to the equation, mint fee is 80 bps. Hence, Cat should get (0.01 * (1-0.008) * 60000)) * 397.3 / 595.7 = 396.9665267752224 PLP.
    // 4. Total supply of PLP should be 397.3 + 396.9665267752224 = 794.2665267752225 PLP
    // 5. Cat's lastAddLiquidityAt should be the current block timestamp
    // 6. Pool's AUM at Max price should be 99.7 + (1 * (1-0.008) * 500) + (0.01 * (1-0.008) * 60000) USD = 1190.9 USD
    // 7. Pool's AUM at Min price should be 99.7 + (1 * (1-0.008) * 400) + (0.01 * (1-0.008) * 60000) USD = 1091.9 USD
    // 8. Pool's totalUsdDebt = 99.7 + (1 * (1-0.008) * 300) + (0.01 * (1-0.008) * 60000) = 992.5 USD
    assertEq(wbtc.balanceOf(CAT), 0);
    assertEq(wbtc.balanceOf(address(pool)), 1000000);
    assertEq(pool.plp().balanceOf(CAT), 396966526775222427396);
    assertEq(pool.plp().totalSupply(), 794266526775222427396);
    assertEq(pool.lastAddLiquidityAtOf(CAT), block.timestamp);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MAX), 1190.9 ether);
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 1091.7 ether);
    assertEq(pool.totalUsdDebt(), 992.5 ether);
  }
}
