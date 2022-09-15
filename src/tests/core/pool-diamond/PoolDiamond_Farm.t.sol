// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolDiamond_BaseTest, LibPoolConfigV1, MockDonateVault, MockStrategy, Pool, console, GetterFacetInterface, LiquidityFacetInterface, stdError } from "./PoolDiamond_BaseTest.t.sol";
import { StrategyInterface } from "../../../interfaces/StrategyInterface.sol";

contract PoolDiamond_FarmTest is PoolDiamond_BaseTest {
  MockDonateVault internal mockDaiVault;
  MockStrategy internal mockDaiVaultStrategy;

  MockDonateVault internal mockWbtcVault;
  MockStrategy internal mockWbtcVaultStrategy;

  MockDonateVault internal mockMaticVault;
  MockStrategy internal mockMaticVaultStrategy;

  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens2,
      LibPoolConfigV1.TokenConfig[] memory tokenConfigs2
    ) = buildDefaultSetTokenConfigInput2();

    poolAdminFacet.setTokenConfigs(tokens2, tokenConfigs2);

    // Feed prices
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);

    // Deploy strategy related-instances

    // DaiVault
    mockDaiVault = new MockDonateVault(address(dai));
    mockDaiVaultStrategy = new MockStrategy(
      address(dai),
      mockDaiVault,
      address(poolDiamond)
    );

    // WbtcVault
    mockWbtcVault = new MockDonateVault(address(wbtc));
    mockWbtcVaultStrategy = new MockStrategy(
      address(wbtc),
      mockWbtcVault,
      address(poolDiamond)
    );

    // MaticVault
    mockMaticVault = new MockDonateVault(address(matic));
    mockMaticVaultStrategy = new MockStrategy(
      address(matic),
      mockMaticVault,
      address(poolDiamond)
    );

    // Set and commit DAI strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);
    vm.warp(block.timestamp + 1 weeks + 1);
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // Set and commit WBTC strategy
    poolFarmFacet.setStrategyOf(address(wbtc), mockWbtcVaultStrategy);
    vm.warp(block.timestamp + 1 weeks + 1);
    poolFarmFacet.setStrategyOf(address(wbtc), mockWbtcVaultStrategy);

    // Set and commit MATIC strategy
    poolFarmFacet.setStrategyOf(address(matic), mockMaticVaultStrategy);
    vm.warp(block.timestamp + 1 weeks + 1);
    poolFarmFacet.setStrategyOf(address(matic), mockMaticVaultStrategy);
  }

  function testCorrectness_WhenAddLiquidity_WhenProfit() external {
    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // Add 1000 DAI to the pool
    dai.mint(address(poolDiamond), 1000 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 1000 * (1-0.003)
    // = 997 DAI
    // 2. Pool's aum by min price should be:
    // = 997 * 1
    // = 997 USD
    // 3. Pool's aum by max price should be:
    // = 997 * 1
    // = 997 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);

    // Call farm to deploy funds 997 * 50% = 498.5 DAI
    poolFarmFacet.farm(address(dai), true);

    // The following conditions should be met:
    // 1. DAI's liquidity should be: 997 DAI
    // 2. DAI's strategy principle should be: 498.5 DAI
    // 3. Pool's aum by min price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 5. Pool's total DAI should be 1000 - 498.5 =  501.5 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 501.5 * 10**18);

    // Add 2000 DAI to the pool
    dai.mint(address(poolDiamond), 2000 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 997 + 2000 * (1-0.003)
    // = 2991 DAI
    // 2. Pool's aum by min price should be:
    // = 2991 * 1
    // = 2991 USD
    // 3. Pool's aum by max price should be:
    // = 2991 * 1
    // = 2991 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 2991 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 2991 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 2991 * 10**18);

    // Assuming vault profit 10 DAI
    dai.mint(address(mockDaiVault), 10 * 10**18);

    // The following conditions should be met:
    // 1. DAI's strategy delta should be: +10 DAI
    // 2. DAI's strategy should be profitable
    // 2. Pool's aum by min price should be:
    // = 2991 * 1 + 10 [StrategyDelta]
    // = 3001 USD
    // 3. Pool's aum by max price should be:
    // = 2991 * 1 + 10 [StrategyDelta]
    // = 3001 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 10 * 10**18);
    assertTrue(isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 3001 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 3001 * 10**18);

    // Add 500 DAI to the pool
    dai.mint(address(poolDiamond), 500 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 2991 + (500 * (1-0.003)) + 10 [StrategyDelta]
    // = 3499.5 DAI
    // 2. Pool's aum by min price should be:
    // = 3489.5 + 10 [StrategyDelta]
    // = 3499.5 USD
    // 3. Pool's aum by max price should be:
    // = 3489.5 + 10 [StrategyDelta]
    // = 3499.5 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 3499.5 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 3499.5 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 3499.5 * 10**18);
  }

  function testCorrectness_WhenAddLiquidity_WhenLoss() external {
    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // Add 1000 DAI to the pool
    dai.mint(address(poolDiamond), 1000 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 1000 * (1-0.003)
    // = 997 DAI
    // 2. Pool's aum by min price should be:
    // = 997 * 1
    // = 997 USD
    // 3. Pool's aum by max price should be:
    // = 997 * 1
    // = 997 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);

    // Call farm to deploy funds 997 * 50% = 498.5 DAI
    poolFarmFacet.farm(address(dai), true);

    // The following conditions should be met:
    // 1. DAI's liquidity should be: 997 DAI
    // 2. DAI's strategy principle should be: 498.5 DAI
    // 3. Pool's aum by min price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 5. Pool's total DAI should be 1000 - 498.5 =  501.5 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 501.5 * 10**18);

    // Add 500 DAI to the pool
    dai.mint(address(poolDiamond), 500 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 997 + 500 * (1-0.003)
    // = 1495.5 DAI
    // 2. Pool's aum by min price should be:
    // = 1495.5 * 1
    // = 1495.5 USD
    // 3. Pool's aum by max price should be:
    // = 1495.5 * 1
    // = 1495.5 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 1495.5 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 1495.5 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 1495.5 * 10**18);

    // Assuming vault loss 20 DAI
    dai.burn(address(mockDaiVault), 20 * 10**18);

    // The following conditions should be met:
    // 1. DAI's strategy delta should be: -20 DAI
    // 2. DAI's strategy should NOT be profitable
    // 2. Pool's aum by min price should be:
    // = 1495.5 * 1 - 20 [StrategyDelta]
    // = 1475.5 USD
    // 3. Pool's aum by max price should be:
    // = 1495.5 * 1 - 20 [StrategyDelta]
    // = 1475.5 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 20 * 10**18);
    assertTrue(!isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 1475.5 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 1475.5 * 10**18);

    // Add 500 DAI to the pool
    dai.mint(address(poolDiamond), 500 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 1495.5 + (500 * (1-0.003)) - 20 [StrategyDelta]
    // = 1974 DAI
    // 2. Pool's aum by min price should be:
    // = 1974 + 0 [StrategyDelta]
    // = 1974 USD
    // 3. Pool's aum by max price should be:
    // = 1974 + 0 [StrategyDelta]
    // = 1974 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 1974 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 1974 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 1974 * 10**18);
  }

  function testCorrectness_WhenRemoveLiquidity_WhenProfit_WhenEnoughBalanceInPool()
    external
  {
    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // Add 1000 DAI to the pool
    dai.mint(address(poolDiamond), 1000 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 1000 * (1-0.003)
    // = 997 DAI
    // 2. Pool's aum by min price should be:
    // = 997 * 1
    // = 997 USD
    // 3. Pool's aum by max price should be:
    // = 997 * 1
    // = 997 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);

    // Call farm to deploy funds 997 * 50% = 498.5 DAI
    poolFarmFacet.farm(address(dai), true);

    // The following conditions should be met:
    // 1. DAI's liquidity should be: 997 DAI
    // 2. DAI's strategy principle should be: 498.5 DAI
    // 3. Pool's aum by min price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 5. Pool's total DAI should be 1000 - 498.5 =  501.5 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 501.5 * 10**18);

    // Assuming profit 20 DAI
    dai.mint(address(mockDaiVault), 20 * 10**18);

    // The following conditions should be met:
    // 1. DAI's strategy delta should be: 20 DAI
    // 2. DAI's strategy should be profitable
    // 3. Pool's aum by min price should be:
    // = 997 * 1 + 20 [StrategyDelta]
    // = 1017 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 + 20 [StrategyDelta]
    // = 1017 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 20 * 10**18);
    assertTrue(isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 1017 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 1017 * 10**18);

    // Warp to pass liquidity cool down
    vm.warp(block.timestamp + 1 days);

    // Remove 400 DAI from the pool
    plp.transfer(
      address(poolDiamond),
      (400 ether * plp.totalSupply()) / poolGetterFacet.getAumE18(false)
    );
    poolLiquidityFacet.removeLiquidity(
      address(this),
      address(dai),
      address(this)
    );

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 997 + 20 - 400
    // = 617 DAI
    // 2. DAI's strategy principle should be: 498.5 DAI
    // 3. Pool's aum by min price should be:
    // = 617 * 1 + 0 [StrategyDelta]
    // = 617
    // 4. Pool's aum by max price should be:
    // = 617 * 1 + 0 [StrategyDelta]
    // = 617
    // 5. address(this) should received:
    // = 400 * (1-0.003)
    // = 398.8 DAI
    // 6. Pool should make:
    // = 3 + (400 * 0.003)
    // = 4.2 DAI
    // 7. Pool's total DAI should be:
    // = 1000 - 498.5 + 20 - 398.8
    // = 122.7 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 617 * 10**18 + 1);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 617 * 10**18 + 1);
    assertEq(poolGetterFacet.getAumE18(true), 617 * 10**18 + 1);
    assertEq(dai.balanceOf(address(this)), 398.8 * 10**18 - 1);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 4.2 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 122.7 * 10**18 + 1);
  }

  function testCorrectness_WhenRemoveLiquidity_WhenProfit_WhenNotEnoughBalanceInPool()
    external
  {
    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // Add 1000 DAI to the pool
    dai.mint(address(poolDiamond), 1000 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 1000 * (1-0.003)
    // = 997 DAI
    // 2. Pool's aum by min price should be:
    // = 997 * 1
    // = 997 USD
    // 3. Pool's aum by max price should be:
    // = 997 * 1
    // = 997 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);

    // Call farm to deploy funds 997 * 50% = 498.5 DAI
    poolFarmFacet.farm(address(dai), true);

    // The following conditions should be met:
    // 1. DAI's liquidity should be: 997 DAI
    // 2. DAI's strategy principle should be: 498.5 DAI
    // 3. Pool's aum by min price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 5. Pool's total DAI should be 1000 - 498.5 =  501.5 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 501.5 * 10**18);

    // Assuming profit 20 DAI
    dai.mint(address(mockDaiVault), 20 * 10**18);

    // The following conditions should be met:
    // 1. DAI's strategy delta should be: 20 DAI
    // 2. DAI's strategy should be profitable
    // 3. Pool's aum by min price should be:
    // = 997 * 1 + 20 [StrategyDelta]
    // = 1017 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 + 20 [StrategyDelta]
    // = 1017 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 20 * 10**18);
    assertTrue(isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 1017 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 1017 * 10**18);

    // Warp to pass liquidity cool down
    vm.warp(block.timestamp + 1 days);

    // Remove 600 DAI from the pool
    plp.transfer(
      address(poolDiamond),
      (600 ether * plp.totalSupply()) / poolGetterFacet.getAumE18(false)
    );
    poolLiquidityFacet.removeLiquidity(
      address(this),
      address(dai),
      address(this)
    );

    (isProfit, strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 997 + 20 - 600
    // = 417 DAI
    // 2. DAI's strategy principle should be:
    // = 498.5 - ((600 * (1-0.003)) [AmountOut] - (501.5 [BalanceBeforeRemoveLiq] + 20 [StrategyDelta] - (3 + 1.8 [FeeReserve])))
    // = 498.5 - 81.5
    // = 417 DAI
    // 3. Pool's aum by min price should be:
    // = 417 * 1 + 0 [StrategyDelta]
    // = 417
    // 4. Pool's aum by max price should be:
    // = 417 * 1 + 0 [StrategyDelta]
    // = 417
    // 5. address(this) should received:
    // = 600 * (1-0.003)
    // = 598.2 DAI
    // 6. Pool should make:
    // = 3 + (600 * 0.003)
    // = 4.8 DAI
    // 7. Pool's total DAI should be: 4.8 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 417 * 10**18 + 1);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      417 * 10**18 + 1
    );
    assertEq(poolGetterFacet.getAumE18(false), 417 * 10**18 + 1);
    assertEq(poolGetterFacet.getAumE18(true), 417 * 10**18 + 1);
    assertEq(dai.balanceOf(address(this)), 598.2 * 10**18 - 1);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 4.8 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 4.8 * 10**18);
  }

  function testCorrectness_WhenRemoveLiquidity_WhenLoss_WhenEnoughBalanceInPool()
    external
  {
    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // Add 1000 DAI to the pool
    dai.mint(address(poolDiamond), 1000 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 1000 * (1-0.003)
    // = 997 DAI
    // 2. Pool's aum by min price should be:
    // = 997 * 1
    // = 997 USD
    // 3. Pool's aum by max price should be:
    // = 997 * 1
    // = 997 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);

    // Call farm to deploy funds 997 * 50% = 498.5 DAI
    poolFarmFacet.farm(address(dai), true);

    // The following conditions should be met:
    // 1. DAI's liquidity should be: 997 DAI
    // 2. DAI's strategy principle should be: 498.5 DAI
    // 3. Pool's aum by min price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 5. Pool's total DAI should be 1000 - 498.5 =  501.5 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 501.5 * 10**18);

    // Assuming loss 20 DAI
    dai.burn(address(mockDaiVault), 20 * 10**18);

    // The following conditions should be met:
    // 1. DAI's strategy delta should be: -20 DAI
    // 2. DAI's strategy should be loss
    // 3. Pool's aum by min price should be:
    // = 997 * 1 - 20 [StrategyDelta]
    // = 977 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 - 20 [StrategyDelta]
    // = 977 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 20 * 10**18);
    assertTrue(!isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 977 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 977 * 10**18);

    // Warp to pass liquidity cool down
    vm.warp(block.timestamp + 1 days);

    // Remove 400 DAI from the pool
    plp.transfer(
      address(poolDiamond),
      (400 ether * plp.totalSupply()) / poolGetterFacet.getAumE18(false)
    );
    poolLiquidityFacet.removeLiquidity(
      address(this),
      address(dai),
      address(this)
    );

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 997 - 20 - 400
    // = 577 DAI
    // 2. DAI's strategy principle should be:
    // = 498.5 - 20
    // = 478.5 DAI
    // 3. Pool's aum by min price should be:
    // = 577 * 1 + 0 [StrategyDelta]
    // = 577
    // 4. Pool's aum by max price should be:
    // = 577 * 1 + 0 [StrategyDelta]
    // = 577
    // 5. address(this) should received:
    // = 400 * (1-0.003)
    // = 398.8 DAI
    // 6. Pool should make:
    // = 3 + (400 * 0.003)
    // = 4.2 DAI
    // 7. Pool's total DAI should be:
    // = 1000 - 498.5 - 398.8
    // = 102.7 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 577 * 10**18 + 1);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      478.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 577 * 10**18 + 1);
    assertEq(poolGetterFacet.getAumE18(true), 577 * 10**18 + 1);
    assertEq(dai.balanceOf(address(this)), 398.8 * 10**18 - 1);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 4.2 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 102.7 * 10**18 + 1);

    // Exit position
    uint256 daiBefore = dai.balanceOf(address(this));
    plp.transfer(address(poolDiamond), plp.balanceOf(address(this)));
    poolLiquidityFacet.removeLiquidity(
      address(this),
      address(dai),
      address(this)
    );
    uint256 daiAfter = dai.balanceOf(address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be: 0
    // 2. DAI's strategy principle should be: 0
    // 3. Pool's aum by min price should be: 0
    // 4. Pool's aum by max price should be: 0
    // 5. address(this) should received:
    // = 577 * (1-0.003)
    // = 575.269 DAI
    // 6. Pool should make:
    // = 4.2 + (577 * 0.003)
    // = 5.931 DAI
    // 7. Pool's total DAI should be:
    // = 5.931 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 0);
    assertEq(poolGetterFacet.strategyDataOf(address(dai)).principle, 0);
    assertEq(poolGetterFacet.getAumE18(false), 0);
    assertEq(poolGetterFacet.getAumE18(true), 0);
    assertEq(daiAfter - daiBefore, 575.269 * 10**18);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 5.931 * 10**18 + 1);
    assertEq(poolGetterFacet.totalOf(address(dai)), 5.931 * 10**18 + 1);
  }

  function testCorrectness_WhenRemoveLiquidity_WhenLoss_WhenNotEnoughBalanceInPool()
    external
  {
    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // Add 1000 DAI to the pool
    dai.mint(address(poolDiamond), 1000 * 10**18);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 1000 * (1-0.003)
    // = 997 DAI
    // 2. Pool's aum by min price should be:
    // = 997 * 1
    // = 997 USD
    // 3. Pool's aum by max price should be:
    // = 997 * 1
    // = 997 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);

    // Call farm to deploy funds 997 * 50% = 498.5 DAI
    poolFarmFacet.farm(address(dai), true);

    // The following conditions should be met:
    // 1. DAI's liquidity should be: 997 DAI
    // 2. DAI's strategy principle should be: 498.5 DAI
    // 3. Pool's aum by min price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 + 0 [StrategyDelta]
    // = 997 USD
    // 5. Pool's total DAI should be 1000 - 498.5 =  501.5 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 501.5 * 10**18);

    // Assuming loss 20 DAI
    dai.burn(address(mockDaiVault), 20 * 10**18);

    // The following conditions should be met:
    // 1. DAI's strategy delta should be: -20 DAI
    // 2. DAI's strategy should be loss
    // 3. Pool's aum by min price should be:
    // = 997 * 1 - 20 [StrategyDelta]
    // = 977 USD
    // 4. Pool's aum by max price should be:
    // = 997 * 1 - 20 [StrategyDelta]
    // = 977 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 20 * 10**18);
    assertTrue(!isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 977 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 977 * 10**18);

    // Warp to pass liquidity cool down
    vm.warp(block.timestamp + 1 days);

    // Remove 600 DAI from the pool
    plp.transfer(
      address(poolDiamond),
      (600 ether * plp.totalSupply()) / poolGetterFacet.getAumE18(false)
    );
    poolLiquidityFacet.removeLiquidity(
      address(this),
      address(dai),
      address(this)
    );

    // The following conditions should be met:
    // 1. DAI's liquidity should be:
    // = 997 - 20 - 600
    // = 377 DAI
    // 2. DAI's strategy principle should be:
    // = (498.5 - 20) - (598.2 - (501.5 - (1.8 + 3)))
    // = 377 DAI
    // 3. Pool's aum by min price should be:
    // = 377 * 1 + 0 [StrategyDelta]
    // = 377
    // 4. Pool's aum by max price should be:
    // = 377 * 1 + 0 [StrategyDelta]
    // = 377
    // 5. address(this) should received:
    // = 600 * (1-0.003)
    // = 598.2 DAI
    // 6. Pool should make:
    // = 3 + (600 * 0.003)
    // = 4.8 DAI
    // 7. Pool's total DAI should be:
    // = 4.8 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 377 * 10**18 + 1);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      377 * 10**18 + 1
    );
    assertEq(poolGetterFacet.getAumE18(false), 377 * 10**18 + 1);
    assertEq(poolGetterFacet.getAumE18(true), 377 * 10**18 + 1);
    assertEq(dai.balanceOf(address(this)), 598.2 * 10**18 - 1);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 4.8 * 10**18);
    assertEq(poolGetterFacet.totalOf(address(dai)), 4.8 * 10**18);

    // Exit position
    uint256 daiBefore = dai.balanceOf(address(this));
    plp.transfer(address(poolDiamond), plp.balanceOf(address(this)));
    poolLiquidityFacet.removeLiquidity(
      address(this),
      address(dai),
      address(this)
    );
    uint256 daiAfter = dai.balanceOf(address(this));

    // The following conditions should be met:
    // 1. DAI's liquidity should be: 0
    // 2. DAI's strategy principle should be: 0
    // 3. Pool's aum by min price should be: 0
    // 4. Pool's aum by max price should be: 0
    // 5. address(this) should received:
    // = 377 * (1-0.003)
    // = 375.869 DAI
    // 6. Pool should make:
    // = 4.8 + (377 * 0.003)
    // = 5.931 DAI
    // 7. Pool's total DAI should be:
    // = 5.931 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 0);
    assertEq(poolGetterFacet.strategyDataOf(address(dai)).principle, 0);
    assertEq(poolGetterFacet.getAumE18(false), 0);
    assertEq(poolGetterFacet.getAumE18(true), 0);
    assertEq(daiAfter - daiBefore, 375.869 * 10**18);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 5.931 * 10**18 + 1);
    assertEq(poolGetterFacet.totalOf(address(dai)), 5.931 * 10**18 + 1);
  }

  function testCorrectness_WhenAddLiquidity_WhenIncreasePosition_WhenLong_WhenProfit()
    external
  {
    wbtc.mint(ALICE, 1 * 10**8);

    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(wbtc), 5000);

    // ----- Start Alice session -----
    vm.startPrank(ALICE);

    // Alice add liquidity with 117499 satoshi
    wbtc.transfer(address(poolDiamond), 117499);
    poolLiquidityFacet.addLiquidity(ALICE, address(wbtc), ALICE);

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
    assertEq(poolGetterFacet.plp().balanceOf(ALICE), 46.8584 * 10**18);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 353);
    assertEq(poolGetterFacet.getAumE18(false), 46.8584 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 48.02986 * 10**18);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 46.8584 * 10**18);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 117146);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      46.8584 * 10**30
    );

    // Call farm to deploy funds 117146 * 50% = 58573 satoshi
    poolFarmFacet.farm(address(wbtc), true);

    // Alice add liquidity again with 117499 satoshi
    wbtc.transfer(address(poolDiamond), 117499);
    poolLiquidityFacet.addLiquidity(ALICE, address(wbtc), ALICE);

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
    // 8. Current WBTC in the pool contract is 234292 - 58573 = 175719 satoshi

    assertEq(
      poolGetterFacet.plp().balanceOf(ALICE),
      92.573912195121951219 ether
    );
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 706);
    assertEq(poolGetterFacet.getAumE18(false), 93.7168 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 96.05972 * 10**18);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 93.7168 * 10**18);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 234292);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      93.7168 * 10**30
    );
    assertEq(
      wbtc.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(wbtc)),
      175719
    );

    // Assuming vault profit 100000 satoshi
    wbtc.mint(address(mockWbtcVault), 100000);

    // The following conditions should be met:
    // 1. Wbtc's strategy delta should be: +100000 satoshi
    // 2. Wbtc's strategy should be profitable
    // 2. Pool's aum by min price should be:
    // = 93.7168 + (0.00100000 * 40000) [StrategyDelta]
    // = 133.7168e18 USD
    // 3. Pool's aum by max price should be:
    // = 96.05972 + (0.00100000 * 41000) [StrategyDelta]
    // = 137.05972e68 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(wbtc)
    );
    assertEq(strategyDelta, 100000);
    assertTrue(isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 133.7168 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 137.05972 * 10**18);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 234292);

    // Increase long position with sub account id = 0
    wbtc.transfer(address(poolDiamond), 22500);
    poolPerpTradeFacet.increasePosition(
      ALICE,
      0,
      address(wbtc),
      address(wbtc),
      49 * 10**30,
      true
    );

    // The following condition expected to be happened:
    // 1. Pool's WBTC liquidity should be:
    // = (234292 + 100001) + 22500 - (((49 * 0.001) + (49 * 0)) / 41000)
    // = 334293 + 22500 - (((49 * 0.001) + (49 * 0)) / 41000)
    // = 334293 + 22500 - 119 = 356674 sathoshi
    // 2. Pool's WBTC reserved should be:
    // = 49 / 40000 = 122500 sathoshi
    // 3. Pool's WBTC guarantee USD should be:
    // = 49 + 0.049 - ((22500 / 1e8) * 40000) = 40.049 USD
    // 4. Redeemable WBTC in USD should be:
    // = ((356674 + 97680 (from 40.049 converting to collateral token) - 122500) / 1e8) * 40000 = 132.7416 USD
    // 5. Pool's AUM by min price should be:
    // 40.049 + ((356673 - 122500) / 1e8) * 40000 = 133.7182 USD
    // 6. Pool's AUM by max price should be:
    // 40.049 + ((356673 - 122500) / 1e8) * 41000 = 136.05993 USD
    // 7. Pool should makes 706 + 119 = 825 sathoshi
    // 8. Pool's WBTC USD debt should still the same as before
    // 9. Pool's WBTC balance should be:
    // = 356674 + 825 (fee) - 58573 (which is in the farm strategy) = 298926 sathoshi
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 356674);
    assertEq(poolGetterFacet.reservedOf(address(wbtc)), 122500);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(wbtc)), 40.049 * 10**30);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      132.7416 * 10**30
    );
    assertEq(poolGetterFacet.getAumE18(false), 133.7182 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 136.05993 * 10**18);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 825);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 93.7168 * 10**18);
    assertEq(wbtc.balanceOf(address(poolDiamond)), 298926);

    // Assert a postion
    // 1. Position's size should be 49 USD
    // 2. Position's collateral should be:
    // = ((22500 / 1e8) * 40000) - 0.049 = 8.951 USD
    // 3. Position's average price should be 41000 USD
    GetterFacetInterface.GetPositionReturnVars memory position = poolGetterFacet
      .getPositionWithSubAccountId(
        ALICE,
        0,
        address(wbtc),
        address(wbtc),
        true
      );
    assertEq(position.size, 49 * 10**30);
    assertEq(position.collateral, 8.951 * 10**30);
    assertEq(position.averagePrice, 41000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 122500);
    assertEq(position.realizedPnl, 0);
    assertTrue(position.hasProfit == true);
    assertEq(position.lastIncreasedTime, block.timestamp);

    vm.stopPrank();
  }

  function testCorrectness_WhenAddLiquidity_WhenIncreasePosition_WhenLong_WhenLoss()
    external
  {
    wbtc.mint(ALICE, 1 * 10**8);

    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(wbtc), 5000);

    // ----- Start Alice session -----
    vm.startPrank(ALICE);

    // Alice add liquidity with 117499 satoshi
    wbtc.transfer(address(poolDiamond), 117499);
    poolLiquidityFacet.addLiquidity(ALICE, address(wbtc), ALICE);

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
    assertEq(poolGetterFacet.plp().balanceOf(ALICE), 46.8584 * 10**18);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 353);
    assertEq(poolGetterFacet.getAumE18(false), 46.8584 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 48.02986 * 10**18);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 46.8584 * 10**18);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 117146);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      46.8584 * 10**30
    );

    // Call farm to deploy funds 117146 * 50% = 58573 satoshi
    poolFarmFacet.farm(address(wbtc), true);

    // Alice add liquidity again with 117499 satoshi
    wbtc.transfer(address(poolDiamond), 117499);
    poolLiquidityFacet.addLiquidity(ALICE, address(wbtc), ALICE);

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
    // 8. Current WBTC in the pool contract is 234292 - 58573 = 175719 satoshi

    assertEq(
      poolGetterFacet.plp().balanceOf(ALICE),
      92.573912195121951219 ether
    );
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 706);
    assertEq(poolGetterFacet.getAumE18(false), 93.7168 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 96.05972 * 10**18);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 93.7168 * 10**18);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 234292);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      93.7168 * 10**30
    );
    assertEq(
      wbtc.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(wbtc)),
      175719
    );

    // Assuming vault lost 50000 satoshi
    wbtc.burn(address(mockWbtcVault), 50000);

    // The following conditions should be met:
    // 1. Wbtc's strategy delta should be: -50000 satoshi
    // 2. Wbtc's strategy should not be profitable
    // 2. Pool's aum by min price should be:
    // = 93.7168 - (0.00050000 * 40000) [StrategyDelta]
    // = 73.7168e18 USD
    // 3. Pool's aum by max price should be:
    // = 96.05972 - (0.00050000 * 41000) [StrategyDelta]
    // = 75.55972e68 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(wbtc)
    );
    assertEq(strategyDelta, 50000);
    assertFalse(isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 73.7168 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 75.55972 * 10**18);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 234292);

    // Increase long position with sub account id = 0
    wbtc.transfer(address(poolDiamond), 22500);
    poolPerpTradeFacet.increasePosition(
      ALICE,
      0,
      address(wbtc),
      address(wbtc),
      49 * 10**30,
      true
    );

    // The following condition expected to be happened:
    // 1. Pool's WBTC liquidity should be:
    // = (234292 - 50000) + 22500 - (((49 * 0.001) + (49 * 0)) / 41000)
    // = 184292 + 22500 - (((49 * 0.001) + (49 * 0)) / 41000)
    // = 184292 + 22500 - 119 = 206673 sathoshi
    // 2. Pool's WBTC reserved should be:
    // = 49 / 40000 = 122500 sathoshi
    // 3. Pool's WBTC guarantee USD should be:
    // = 49 + 0.049 - ((22500 / 1e8) * 40000) = 40.049 USD
    // 4. Redeemable WBTC in USD should be:
    // = ((206673 + 97680 (from 40.049 converting to collateral token) - 122500) / 1e8) * 40000
    // = ((206673 + 97680 - 122500) / 1e8) * 40000 = 72.7412 USD
    // 5. Pool's AUM by min price should be:
    // 40.049 + ((206673 - 122500) / 1e8) * 40000 = 73.7182 USD
    // 6. Pool's AUM by max price should be:
    // 40.049 + ((206673 - 122500) / 1e8) * 41000 = 74.55993 USD
    // 7. Pool should makes 706 + 119 = 825 sathoshi
    // 8. Pool's WBTC USD debt should still the same as before
    // 9. Pool's WBTC balance should be:
    // = 206673 + 825 (fee) - 8573 (which is in the farm strategy) = 198925 sathoshi
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 206673);
    assertEq(poolGetterFacet.reservedOf(address(wbtc)), 122500);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(wbtc)), 40.049 * 10**30);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      72.7412 * 10**30
    );
    assertEq(poolGetterFacet.getAumE18(false), 73.7182 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 74.55993 * 10**18);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 825);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 93.7168 * 10**18);
    assertEq(wbtc.balanceOf(address(poolDiamond)), 198925);

    // Assert a postion
    // 1. Position's size should be 49 USD
    // 2. Position's collateral should be:
    // = ((22500 / 1e8) * 40000) - 0.049 = 8.951 USD
    // 3. Position's average price should be 41000 USD
    GetterFacetInterface.GetPositionReturnVars memory position = poolGetterFacet
      .getPositionWithSubAccountId(
        ALICE,
        0,
        address(wbtc),
        address(wbtc),
        true
      );
    assertEq(position.size, 49 * 10**30);
    assertEq(position.collateral, 8.951 * 10**30);
    assertEq(position.averagePrice, 41000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 122500);
    assertEq(position.realizedPnl, 0);
    assertTrue(position.hasProfit == true);
    assertEq(position.lastIncreasedTime, block.timestamp);

    vm.stopPrank();
  }

  function testCorrectness_WhenAddLiquidity_WhenIncreasePosition_WhenShort_WhenProfit()
    external
  {
    // Initialized price feeds
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60_000 * 10**8);
    maticPriceFeed.setLatestAnswer(1000 * 10**8);

    // Set mintBurnFeeBps to 4 BPS
    poolAdminFacet.setMintBurnFeeBps(4);

    // Feed WBTC price to be 40,000 USD
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    // Mint 1,000 DAI to Alice
    dai.mint(ALICE, 1000 * 10**18);

    // Mint 1 WBTC to this address
    wbtc.mint(address(this), 1 * 10**8);

    // Set strategy target bps for WBTC to be 50%
    poolFarmFacet.setStrategyTargetBps(address(wbtc), 5000);
    // Set strategy target bps for DAI to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // Performs add liquidity with 117499 satoshi
    wbtc.transfer(address(poolDiamond), 117499);
    poolLiquidityFacet.addLiquidity(
      address(this),
      address(wbtc),
      address(this)
    );

    // --- Start Alice session --- //
    vm.startPrank(ALICE);

    // Alice performs add liquidity by a 500 DAI
    dai.transfer(address(poolDiamond), 500 * 10**18);
    poolLiquidityFacet.addLiquidity(ALICE, address(dai), ALICE);

    // The following conditions need to be met:
    // 1. Pool's DAI liquidity should be 500 * (1-0.0004) = 499.8 DAI
    // 2. Pool should make 0.2 DAI in fee
    // 3. Pool's DAI usd debt should be 499.8 USD
    // 4. Redemptable DAI collateral should be 499.8 USD
    // 5. Pool's AUM by min price should be 499.8 + (0.00117499 * (1-0.0004) * 40000) = 546.7808 USD
    // 6. Pool's AUM by max price should be 499.8 + (0.00117499 * (1-0.0004) * 40000) = 546.7808 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 499.8 * 10**18);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 0.2 * 10**18);
    assertEq(poolGetterFacet.usdDebtOf(address(dai)), 499.8 * 10**18);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(dai)),
      499.8 * 10**30
    );
    assertEq(poolGetterFacet.getAumE18(false), 546.7808 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 546.7808 * 10**18);

    vm.stopPrank();
    // ---- Stop Alice session ---- //

    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);

    // Call farm to deploy funds 117499 - 47 (from 4 BPS fee) * 50% = 58726 satoshi
    poolFarmFacet.farm(address(wbtc), true);
    // Call farm to deploy funds 499.8 * 50% = 249.9 DAI
    poolFarmFacet.farm(address(dai), true);

    assertEq(poolGetterFacet.liquidityOf(address(dai)), 499.8 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 117452);
    assertEq(
      dai.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(dai)),
      249.9 ether
    );
    assertEq(
      wbtc.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(wbtc)),
      58726
    );

    // ---- Start Alice session ---- //
    vm.startPrank(ALICE);

    // Assuming WBTC vault profits 100000 satoshi
    wbtc.mint(address(mockWbtcVault), 100000);
    // Assuming DAI vault profits 20 DAI
    dai.mint(address(mockDaiVault), 20 * 10**18);

    // Alice opens a 90 USD WBTC short position with 20 DAI as a collateral
    dai.transfer(address(poolDiamond), 20 * 10**18);
    poolPerpTradeFacet.increasePosition(
      ALICE,
      0,
      address(dai),
      address(wbtc),
      90 * 10**30,
      false
    );

    // The following conditions need to be met:
    // 1. Pool's DAI liquidity should be the same.
    // 2. Pool's DAI USD debt should be the same.
    // 2. Pool's DAI reserved should be 90 DAI
    // 3. Pool's guaranteed USD should be 0
    // 4. Redemptable DAI collateral should be 499.8 USD + 20 USD (from farm strategy profit) = 519.8 USD
    // 5. Pool should makes 0.2 + ((90 * 0.001)) = 0.29 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 519.8 * 10**18);
    assertEq(poolGetterFacet.usdDebtOf(address(dai)), 499.8 * 10**18);
    assertEq(poolGetterFacet.reservedOf(address(dai)), 90 * 10**18);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(dai)), 0 * 10**18);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(dai)),
      519.8 * 10**30
    );
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 0.29 * 10**18);
    assertEq(poolGetterFacet.shortSizeOf(address(wbtc)), 90 * 10**30);
    assertEq(
      poolGetterFacet.shortAveragePriceOf(address(wbtc)),
      40_000 * 10**30
    );

    // Assert a position:
    // 1. Position's size should be 90
    // 2. Position's collateral should be 20 - (90 * 0.001) = 19.91 DAI
    // 3. Position's averagePrice should be 40,000 USD
    // 4. Position's entry funding rate should be 0
    // 5. Position's reserve amount should be 90 DAI
    // 6. Position should be in profit
    // 7. Position's lastIncreasedTime should be block.timestamp
    GetterFacetInterface.GetPositionReturnVars memory position = poolGetterFacet
      .getPositionWithSubAccountId(
        ALICE,
        0,
        address(dai),
        address(wbtc),
        false
      );
    assertEq(position.size, 90 * 10**30);
    assertEq(position.collateral, 19.91 * 10**30);
    assertEq(position.averagePrice, 40_000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 90 * 10**18);
    assertTrue(position.hasProfit);
    assertEq(position.lastIncreasedTime, block.timestamp);

    // Assert pool's short delta
    // 1. Pool's delta should be (90 * (40000 - 41000)) / 40000 = -2.25 USD
    // 2. Pool's short should be not profitable
    (bool isProfit, uint256 delta) = poolGetterFacet.getPoolShortDelta(
      address(wbtc)
    );
    assertFalse(isProfit);
    assertEq(delta, 2.25 * 10**30);

    // Assert position's delta
    // 1. Position's delta should be (90 * (40000 - 41000)) / 40000 = -2.25 USD
    // 2. Position's short should be not profitable
    (isProfit, delta) = poolGetterFacet.getPositionDelta(
      ALICE,
      0,
      address(dai),
      address(wbtc),
      false
    );
    assertFalse(isProfit);
    assertEq(delta, 2.25 * 10**30);

    vm.stopPrank();

    // Make WBTC price pump to 42,000 USD
    wbtcPriceFeed.setLatestAnswer(42_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(42_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(42_000 * 10**8);

    vm.startPrank(ALICE);

    // Assert pool's short delta
    // 1. Pool's delta should be (90 * (40000 - 42000)) / 40000 = -4.5 USD
    // 2. Pool's short should be not profitable
    (isProfit, delta) = poolGetterFacet.getPoolShortDelta(address(wbtc));
    assertFalse(isProfit);
    assertEq(delta, 4.5 * 10**30);

    // Assert position's delta
    // 1. Position's delta should be (90 * (40000 - 42000)) / 40000 = -4.5 USD
    // 2. Position's short should be not profitable
    (isProfit, delta) = poolGetterFacet.getPositionDelta(
      ALICE,
      0,
      address(dai),
      address(wbtc),
      false
    );
    assertFalse(isProfit);
    assertEq(delta, 4.5 * 10**30);
  }

  function testCorrectness_WhenAddLiquidity_WhenIncreasePosition_WhenShort_WhenLoss()
    external
  {
    // Initialized price feeds
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60_000 * 10**8);
    maticPriceFeed.setLatestAnswer(1000 * 10**8);

    // Set mintBurnFeeBps to 4 BPS
    poolAdminFacet.setMintBurnFeeBps(4);

    // Feed WBTC price to be 40,000 USD
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10**8);

    // Mint 1,000 DAI to Alice
    dai.mint(ALICE, 1000 * 10**18);

    // Mint 1 WBTC to this address
    wbtc.mint(address(this), 1 * 10**8);

    // Set strategy target bps for WBTC to be 50%
    poolFarmFacet.setStrategyTargetBps(address(wbtc), 5000);
    // Set strategy target bps for DAI to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // Performs add liquidity with 117499 satoshi
    wbtc.transfer(address(poolDiamond), 117499);
    poolLiquidityFacet.addLiquidity(
      address(this),
      address(wbtc),
      address(this)
    );

    // --- Start Alice session --- //
    vm.startPrank(ALICE);

    // Alice performs add liquidity by a 500 DAI
    dai.transfer(address(poolDiamond), 500 * 10**18);
    poolLiquidityFacet.addLiquidity(ALICE, address(dai), ALICE);

    // The following conditions need to be met:
    // 1. Pool's DAI liquidity should be 500 * (1-0.0004) = 499.8 DAI
    // 2. Pool should make 0.2 DAI in fee
    // 3. Pool's DAI usd debt should be 499.8 USD
    // 4. Redemptable DAI collateral should be 499.8 USD
    // 5. Pool's AUM by min price should be 499.8 + (0.00117499 * (1-0.0004) * 40000) = 546.7808 USD
    // 6. Pool's AUM by max price should be 499.8 + (0.00117499 * (1-0.0004) * 40000) = 546.7808 USD (based on the test case, min price currently equals to max price)
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 499.8 * 10**18);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 0.2 * 10**18);
    assertEq(poolGetterFacet.usdDebtOf(address(dai)), 499.8 * 10**18);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(dai)),
      499.8 * 10**30
    );
    assertEq(poolGetterFacet.getAumE18(false), 546.7808 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 546.7808 * 10**18);

    vm.stopPrank();
    // ---- Stop Alice session ---- //

    wbtcPriceFeed.setLatestAnswer(41_000 * 10**8);

    // Call farm to deploy funds 117499 - 47 (from 4 BPS fee) * 50% = 58726 satoshi
    poolFarmFacet.farm(address(wbtc), true);
    // Call farm to deploy funds 499.8 * 50% = 249.9 DAI
    poolFarmFacet.farm(address(dai), true);

    assertEq(poolGetterFacet.liquidityOf(address(dai)), 499.8 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 117452);
    assertEq(
      dai.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(dai)),
      249.9 ether
    );
    assertEq(
      wbtc.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(wbtc)),
      58726
    );

    // ---- Start Alice session ---- //
    vm.startPrank(ALICE);

    // Assuming WBTC vault profits 50000 satoshi
    wbtc.burn(address(mockWbtcVault), 50000);
    // Assuming DAI vault profits 20 DAI
    dai.burn(address(mockDaiVault), 20 * 10**18);

    // Alice opens a 90 USD WBTC short position with 20 DAI as a collateral
    dai.transfer(address(poolDiamond), 20 * 10**18);
    poolPerpTradeFacet.increasePosition(
      ALICE,
      0,
      address(dai),
      address(wbtc),
      90 * 10**30,
      false
    );

    // The following conditions need to be met:
    // 1. Pool's DAI liquidity should be the same.
    // 2. Pool's DAI USD debt should be the same.
    // 2. Pool's DAI reserved should be 90 DAI
    // 3. Pool's guaranteed USD should be 0
    // 4. Redemptable DAI collateral should be 499.8 USD - 20 USD (from farm strategy profit) = 479.8 USD
    // 5. Pool should makes 0.2 + ((90 * 0.001)) = 0.29 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 479.8 * 10**18);
    assertEq(poolGetterFacet.usdDebtOf(address(dai)), 499.8 * 10**18);
    assertEq(poolGetterFacet.reservedOf(address(dai)), 90 * 10**18);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(dai)), 0 * 10**18);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(dai)),
      479.8 * 10**30
    );
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 0.29 * 10**18);
    assertEq(poolGetterFacet.shortSizeOf(address(wbtc)), 90 * 10**30);
    assertEq(
      poolGetterFacet.shortAveragePriceOf(address(wbtc)),
      40_000 * 10**30
    );

    // Assert a position:
    // 1. Position's size should be 90
    // 2. Position's collateral should be 20 - (90 * 0.001) = 19.91 DAI
    // 3. Position's averagePrice should be 40,000 USD
    // 4. Position's entry funding rate should be 0
    // 5. Position's reserve amount should be 90 DAI
    // 6. Position should be in profit
    // 7. Position's lastIncreasedTime should be block.timestamp
    GetterFacetInterface.GetPositionReturnVars memory position = poolGetterFacet
      .getPositionWithSubAccountId(
        ALICE,
        0,
        address(dai),
        address(wbtc),
        false
      );
    assertEq(position.size, 90 * 10**30);
    assertEq(position.collateral, 19.91 * 10**30);
    assertEq(position.averagePrice, 40_000 * 10**30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 90 * 10**18);
    assertTrue(position.hasProfit);
    assertEq(position.lastIncreasedTime, block.timestamp);

    // Assert pool's short delta
    // 1. Pool's delta should be (90 * (40000 - 41000)) / 40000 = -2.25 USD
    // 2. Pool's short should be not profitable
    (bool isProfit, uint256 delta) = poolGetterFacet.getPoolShortDelta(
      address(wbtc)
    );
    assertFalse(isProfit);
    assertEq(delta, 2.25 * 10**30);

    // Assert position's delta
    // 1. Position's delta should be (90 * (40000 - 41000)) / 40000 = -2.25 USD
    // 2. Position's short should be not profitable
    (isProfit, delta) = poolGetterFacet.getPositionDelta(
      ALICE,
      0,
      address(dai),
      address(wbtc),
      false
    );
    assertFalse(isProfit);
    assertEq(delta, 2.25 * 10**30);

    vm.stopPrank();

    // Make WBTC price pump to 42,000 USD
    wbtcPriceFeed.setLatestAnswer(42_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(42_000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(42_000 * 10**8);

    vm.startPrank(ALICE);

    // Assert pool's short delta
    // 1. Pool's delta should be (90 * (40000 - 42000)) / 40000 = -4.5 USD
    // 2. Pool's short should be not profitable
    (isProfit, delta) = poolGetterFacet.getPoolShortDelta(address(wbtc));
    assertFalse(isProfit);
    assertEq(delta, 4.5 * 10**30);

    // Assert position's delta
    // 1. Position's delta should be (90 * (40000 - 42000)) / 40000 = -4.5 USD
    // 2. Position's short should be not profitable
    (isProfit, delta) = poolGetterFacet.getPositionDelta(
      ALICE,
      0,
      address(dai),
      address(wbtc),
      false
    );
    assertFalse(isProfit);
    assertEq(delta, 4.5 * 10**30);
  }

  function testCorrectness_WhenAddLiquidity_WhenSwap_WhenProfit() external {
    // Reset latest 3
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    matic.mint(ALICE, 200 ether);
    wbtc.mint(ALICE, 1 * 10**8);

    // Set strategy target bps for WBTC to be 95%
    poolFarmFacet.setStrategyTargetBps(address(wbtc), 9500);
    // Set strategy target bps for MATIC to be 95%
    poolFarmFacet.setStrategyTargetBps(address(matic), 9500);

    // ------- Alice session START -------
    vm.startPrank(ALICE);

    // Alice add liquidity 200 MATIC (~$60,000)
    matic.transfer(address(poolDiamond), 200 ether);
    poolLiquidityFacet.addLiquidity(ALICE, address(matic), ALICE);

    // Alice add 200 MATIC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 200 * (1-0.003) * 300 = 59820 USD in AUM
    assertEq(poolGetterFacet.getAumE18(false), 59820 ether);

    // Alice add liquidity 1 WBTC (~$60,000)
    wbtc.transfer(address(poolDiamond), 1 * 10**8);
    poolLiquidityFacet.addLiquidity(ALICE, address(wbtc), ALICE);

    // Alice add another 1 WBTC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 59,820 + (1 * (1-0.003) * 60000) = 119,640 USD in AUM
    // 2. Alice should have 119,640 PLP
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make 1 * 0.003 = 0.003 WBTC in fee
    // 5. USD debt for MATIC should be 59,820 USD
    // 6. USD debt for WBTC should be 59,820 USD
    // 7. Pool's MATIC liquidity should be 200 * (1-0.003) = 199.4 MATIC
    // 8. Pool's WBTC liquidity should be 1 * (1-0.003) = 0.997 WBTC
    assertEq(poolGetterFacet.getAumE18(false), 119640 ether);
    assertEq(poolGetterFacet.plp().balanceOf(ALICE), 119640 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(matic)), 0.6 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 300000);
    assertEq(poolGetterFacet.usdDebtOf(address(matic)), 59820 ether);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 59820 ether);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 199.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.997 * 10**8);

    vm.stopPrank();
    // ------- Alice session END -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(600 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);

    // Oracle price updates, the following condition is expected:
    // 1. Pool should have (199.4 * 400) + (0.997 * 60000) = 139,580 USD
    assertEq(poolGetterFacet.getAumE18(false), 139580 ether);

    wbtcPriceFeed.setLatestAnswer(90000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(100000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(80000 * 10**8);

    // Oracle price updates, the following condition is expected:
    // 1. Pool should have (199.4 * 400) + (0.997 * 80000) = 159,520 USD
    assertEq(poolGetterFacet.getAumE18(false), 159520 ether);

    matic.mint(BOB, 100 ether);

    // Call farm to deploy funds 0.997 * 95% = 0.94715, hence balance of pool (excluded fee) will be 0.997 - 0.94715 = 0.04985
    poolFarmFacet.farm(address(wbtc), true);
    // Call farm to deploy funds 199.4 * 95% = 189.43, hence balance of pool (excluded fee) will be 199.4 - 189.43 = 9.97
    poolFarmFacet.farm(address(matic), true);

    assertEq(poolGetterFacet.liquidityOf(address(matic)), 199.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.997 * 10**8);
    assertEq(
      matic.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(matic)),
      9.97 ether
    );
    assertEq(
      wbtc.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(wbtc)),
      0.04985 * 10**8
    );

    // Assuming WBTC vault profits 100000 satoshi
    wbtc.mint(address(mockWbtcVault), 100000);
    // Assuming MATIC vault profits 20 MATIC
    matic.mint(address(mockMaticVault), 20 ether);

    // ------- Bob session START -------
    vm.startPrank(BOB);

    // Bob swap 100 MATIC for WBTC
    matic.transfer(address(poolDiamond), 100 ether);
    poolLiquidityFacet.swap(address(matic), address(wbtc), 0, BOB);

    // After Bob swap, the following condition is expected:
    // 1. Pool should have ((199.4 + 20) * 400) + ((0.997 + 0.001)  * 80000) + (100 * 400) - ((100 * 400 / 100000) * 80000) = 175600 USD in AUM
    // 2. Bob should get (100 * 400 / 100000) * (1 - 0.003) = 0.3988 WBTC
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make (1 * 0.003) + ((100 * 400 / 100000) * 0.003) = 0.0042 WBTC in fee
    // 5. USD debt for MATIC should be 59820 + (100 * 400) = 99820 USD
    // 6. USD debt for WBTC should be 59820 - (100 * 400) = 19820 USD
    // 7. Pool's MATIC liquidity should be 199.4 + 100 + 20 (from farm strategy profits) = 319.4 MATIC
    // 8. Pool's WBTC liquidity should be 0.997 - ((100 * 400 / 100000)) + 0.001 (from farm strategy profits) = 0.598 WBTC
    assertEq(poolGetterFacet.getAumE18(false), 175600 ether);
    assertEq(wbtc.balanceOf(BOB), 0.3988 * 10**8);
    assertEq(poolGetterFacet.feeReserveOf(address(matic)), 0.6 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 0.0042 * 10**8);
    assertEq(poolGetterFacet.usdDebtOf(address(matic)), 99820 ether);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 19820 ether);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 319.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.598 * 10**8);

    vm.stopPrank();
    // ------- Bob session END -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);
    maticPriceFeed.setLatestAnswer(450 * 10**8);

    // ------- Alice session START -------
    vm.startPrank(ALICE);

    // Warp so that Alice can withdraw her PLP
    vm.warp(block.timestamp + 1 days + 1);

    // Alice remove 50000 USD worth of PLP from the pool with MATIC as tokenOut
    poolGetterFacet.plp().transfer(
      address(poolDiamond),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );
    poolLiquidityFacet.removeLiquidity(ALICE, address(matic), ALICE);

    assertEq(poolGetterFacet.plp().balanceOf(address(poolDiamond)), 0);

    // Alice expected to get 50000 / 500 * (1-0.003) = 99.7 MATIC
    assertEq(matic.balanceOf(ALICE), 99699999999999999999);

    // Alice remove 50000 USD worth of PLP from the pool with WBTC as tokenOut
    poolGetterFacet.plp().transfer(
      address(poolDiamond),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );
    poolLiquidityFacet.removeLiquidity(ALICE, address(wbtc), ALICE);

    // Alice expected to get 50000 / 100000 * (1-0.003) = 0.4985 WBTC
    assertEq(wbtc.balanceOf(ALICE), 49849999);

    // Alice try remove 10000 USD worth of PLP from the pool with WBTC as tokenOut
    // Pool doesn't has any liquidity left, so this should revert
    uint256 plpNeeded = (10_000 ether * poolGetterFacet.plp().totalSupply()) /
      poolGetterFacet.getAumE18(false);
    poolGetterFacet.plp().transfer(address(poolDiamond), plpNeeded);
    vm.expectRevert(stdError.arithmeticError);
    poolLiquidityFacet.removeLiquidity(ALICE, address(wbtc), ALICE);
  }

  function testCorrectness_WhenAddLiquidity_WhenSwap_WhenLoss() external {
    // Reset latest 3
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    matic.mint(ALICE, 200 ether);
    wbtc.mint(ALICE, 1 * 10**8);

    // Set strategy target bps for WBTC to be 95%
    poolFarmFacet.setStrategyTargetBps(address(wbtc), 9500);
    // Set strategy target bps for MATIC to be 95%
    poolFarmFacet.setStrategyTargetBps(address(matic), 9500);

    // ------- Alice session START -------
    vm.startPrank(ALICE);

    // Alice add liquidity 200 MATIC (~$60,000)
    matic.transfer(address(poolDiamond), 200 ether);
    poolLiquidityFacet.addLiquidity(ALICE, address(matic), ALICE);

    // Alice add 200 MATIC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 200 * (1-0.003) * 300 = 59820 USD in AUM
    assertEq(poolGetterFacet.getAumE18(false), 59820 ether);

    // Alice add liquidity 1 WBTC (~$60,000)
    wbtc.transfer(address(poolDiamond), 1 * 10**8);
    poolLiquidityFacet.addLiquidity(ALICE, address(wbtc), ALICE);

    // Alice add another 1 WBTC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 59,820 + (1 * (1-0.003) * 60000) = 119,640 USD in AUM
    // 2. Alice should have 119,640 PLP
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make 1 * 0.003 = 0.003 WBTC in fee
    // 5. USD debt for MATIC should be 59,820 USD
    // 6. USD debt for WBTC should be 59,820 USD
    // 7. Pool's MATIC liquidity should be 200 * (1-0.003) = 199.4 MATIC
    // 8. Pool's WBTC liquidity should be 1 * (1-0.003) = 0.997 WBTC
    assertEq(poolGetterFacet.getAumE18(false), 119640 ether);
    assertEq(poolGetterFacet.plp().balanceOf(ALICE), 119640 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(matic)), 0.6 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 300000);
    assertEq(poolGetterFacet.usdDebtOf(address(matic)), 59820 ether);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 59820 ether);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 199.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.997 * 10**8);

    vm.stopPrank();
    // ------- Alice session END -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(600 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);

    // Oracle price updates, the following condition is expected:
    // 1. Pool should have (199.4 * 400) + (0.997 * 60000) = 139,580 USD
    assertEq(poolGetterFacet.getAumE18(false), 139580 ether);

    wbtcPriceFeed.setLatestAnswer(90000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(100000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(80000 * 10**8);

    // Oracle price updates, the following condition is expected:
    // 1. Pool should have (199.4 * 400) + (0.997 * 80000) = 159,520 USD
    assertEq(poolGetterFacet.getAumE18(false), 159520 ether);

    matic.mint(BOB, 100 ether);

    // Call farm to deploy funds 0.997 * 95% = 0.94715, hence balance of pool (excluded fee) will be 0.997 - 0.94715 = 0.04985
    poolFarmFacet.farm(address(wbtc), true);
    // Call farm to deploy funds 199.4 * 95% = 189.43, hence balance of pool (excluded fee) will be 199.4 - 189.43 = 9.97
    poolFarmFacet.farm(address(matic), true);

    assertEq(poolGetterFacet.liquidityOf(address(matic)), 199.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.997 * 10**8);
    assertEq(
      matic.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(matic)),
      9.97 ether
    );
    assertEq(
      wbtc.balanceOf(address(poolDiamond)) -
        poolGetterFacet.feeReserveOf(address(wbtc)),
      0.04985 * 10**8
    );

    // Assuming WBTC vault loss 50000 satoshi
    wbtc.burn(address(mockWbtcVault), 50000);
    // Assuming MATIC vault loss 20 MATIC
    // NOTE: Since matic is a Wnative token, hence needs to do this workaround to do something similar to burn mechanism
    vm.prank(address(mockMaticVault), address(mockMaticVault));
    matic.transfer(address(0), 20 ether);

    // ------- Bob session START -------
    vm.startPrank(BOB);

    // Bob swap 100 MATIC for WBTC
    matic.transfer(address(poolDiamond), 100 ether);
    poolLiquidityFacet.swap(address(matic), address(wbtc), 0, BOB);

    // After Bob swap, the following condition is expected:
    // 1. Pool should have ((199.4 - 20) * 400) + ((0.997 - 0.0005)  * 80000) + (100 * 400) - ((100 * 400 / 100000) * 80000) = 159480 USD in AUM
    // 2. Bob should get (100 * 400 / 100000) * (1 - 0.003) = 0.3988 WBTC
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make (1 * 0.003) + ((100 * 400 / 100000) * 0.003) = 0.0042 WBTC in fee
    // 5. USD debt for MATIC should be 59820 + (100 * 400) = 99820 USD
    // 6. USD debt for WBTC should be 59820 - (100 * 400) = 19820 USD
    // 7. Pool's MATIC liquidity should be 199.4 + 100 - 20 (from farm strategy profits) = 279.4 MATIC
    // 8. Pool's WBTC liquidity should be 0.997 - ((100 * 400 / 100000)) - 0.0005 (from farm strategy profits) = 0.5965 WBTC
    assertEq(poolGetterFacet.getAumE18(false), 159480 ether);
    assertEq(wbtc.balanceOf(BOB), 0.3988 * 10**8);
    assertEq(poolGetterFacet.feeReserveOf(address(matic)), 0.6 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 0.0042 * 10**8);
    assertEq(poolGetterFacet.usdDebtOf(address(matic)), 99820 ether);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 19820 ether);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 279.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.5965 * 10**8);

    vm.stopPrank();
    // ------- Bob session END -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);
    maticPriceFeed.setLatestAnswer(450 * 10**8);

    // ------- Alice session START -------
    vm.startPrank(ALICE);

    // Warp so that Alice can withdraw her PLP
    vm.warp(block.timestamp + 1 days + 1);

    // Alice remove 50000 USD worth of PLP from the pool with MATIC as tokenOut
    poolGetterFacet.plp().transfer(
      address(poolDiamond),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );
    poolLiquidityFacet.removeLiquidity(ALICE, address(matic), ALICE);

    assertEq(poolGetterFacet.plp().balanceOf(address(poolDiamond)), 0);

    // Alice expected to get 50000 / 500 * (1-0.003) = 99.7 MATIC
    assertEq(matic.balanceOf(ALICE), 99699999999999999999);

    // Alice remove 50000 USD worth of PLP from the pool with WBTC as tokenOut
    poolGetterFacet.plp().transfer(
      address(poolDiamond),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );
    poolLiquidityFacet.removeLiquidity(ALICE, address(wbtc), ALICE);

    // Alice expected to get 50000 / 100000 * (1-0.003) = 0.4985 WBTC
    assertEq(wbtc.balanceOf(ALICE), 49849999);

    // Alice try remove 10000 USD worth of PLP from the pool with WBTC as tokenOut
    // Pool doesn't has any liquidity left, so this should revert
    uint256 plpNeeded = (10_000 ether * poolGetterFacet.plp().totalSupply()) /
      poolGetterFacet.getAumE18(false);
    poolGetterFacet.plp().transfer(address(poolDiamond), plpNeeded);
    vm.expectRevert(stdError.arithmeticError);
    poolLiquidityFacet.removeLiquidity(ALICE, address(wbtc), ALICE);
  }
}
