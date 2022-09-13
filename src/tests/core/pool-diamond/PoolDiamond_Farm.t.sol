// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolDiamond_BaseTest, LibPoolConfigV1, MockDonateVault, MockStrategy, Pool, console, GetterFacetInterface, LiquidityFacetInterface } from "./PoolDiamond_BaseTest.t.sol";
import { StrategyInterface } from "../../../interfaces/StrategyInterface.sol";

contract PoolDiamond_FarmTest is PoolDiamond_BaseTest {
  MockDonateVault internal mockDaiVault;
  MockStrategy internal mockDaiVaultStrategy;

  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens2,
      LibPoolConfigV1.TokenConfig[] memory tokenConfigs2
    ) = buildDefaultSetTokenConfigInput2();

    poolAdminFacet.setTokenConfigs(tokens2, tokenConfigs2);

    // Feed prices
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);

    // Deploy strategy related-instances
    mockDaiVault = new MockDonateVault(address(dai));
    mockDaiVaultStrategy = new MockStrategy(
      address(dai),
      mockDaiVault,
      address(poolDiamond)
    );

    // Set and commit DAI strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);
    vm.warp(block.timestamp + 1 weeks + 1);
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);
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
    // 2. DAI's strategy should be profitable
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
}
