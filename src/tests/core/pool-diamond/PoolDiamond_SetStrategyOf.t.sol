// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { PoolDiamond_BaseTest, LibPoolConfigV1, MockDonateVault, MockStrategy, Pool, console, GetterFacetInterface, LiquidityFacetInterface } from "./PoolDiamond_BaseTest.t.sol";
import { StrategyInterface } from "../../../interfaces/StrategyInterface.sol";

contract PoolDiamond_SetStrategyOf is PoolDiamond_BaseTest {
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
  }

  function testRevert_WhenNotOwner() external {
    vm.startPrank(ALICE);

    vm.expectRevert("LibDiamond: Must be contract owner");
    poolFarmFacet.setStrategyOf(address(dai), StrategyInterface(address(0)));

    vm.stopPrank();
  }

  function testRevert_WhenEarlyCommitStrategy() external {
    // Set DAI strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // The following conditions should be met:
    // 1. The strategy is in pending state
    // 2. DAI's strategy startTimestamp should be block.timestamp + 1 weeks
    // 3. DAI's strategy principle should be 0
    // 4. DAI's strategy target bps should be 0
    LibPoolConfigV1.StrategyData memory strategyData = poolGetterFacet
      .strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(mockDaiVaultStrategy)
    );
    assertEq(strategyData.startTimestamp, block.timestamp + 1 weeks);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 0);

    // Try to commit the strategy, this should revert
    vm.expectRevert(
      abi.encodeWithSignature("FarmFacet_TooEarlyToCommitStrategy()")
    );
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);
  }

  function testCorrectness_WhenCommitStrategyAfterStrategyDelay() external {
    // Set DAI strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // The following conditions should be met:
    // 1. The strategy is in pending state
    // 2. DAI's strategy startTimestamp should be block.timestamp + 1 weeks
    // 3. DAI's strategy principle should be 0
    // 4. DAI's strategy target bps should be 0
    LibPoolConfigV1.StrategyData memory strategyData = poolGetterFacet
      .strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(mockDaiVaultStrategy)
    );
    assertEq(strategyData.startTimestamp, block.timestamp + 1 weeks);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 0);

    // Warp to 1 week later
    vm.warp(block.timestamp + 1 weeks);

    // Commit the strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // The following conditions should be met:
    // 1. DAI's pending strategy should be address(0)
    // 2. DAI's strategy should be mockDaiVaultStrategy
    // 3. DAI's strategy startTimestamp should be 0
    // 4. DAI's strategy principle should be 0
    // 5. DAI's strategy target bps should be 0
    strategyData = poolGetterFacet.strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(0)
    );
    assertEq(
      address(poolGetterFacet.strategyOf(address(dai))),
      address(mockDaiVaultStrategy)
    );
    assertEq(strategyData.startTimestamp, 0);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 0);
  }

  function testCorrectness_WhenReplacePendingStrategy() external {
    // Set DAI strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // The following conditions should be met:
    // 1. The strategy is in pending state
    // 2. DAI's strategy startTimestamp should be block.timestamp + 1 weeks
    // 3. DAI's strategy principle should be 0
    // 4. DAI's strategy target bps should be 0
    LibPoolConfigV1.StrategyData memory strategyData = poolGetterFacet
      .strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(mockDaiVaultStrategy)
    );
    assertEq(strategyData.startTimestamp, block.timestamp + 1 weeks);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 0);

    // Warp to 5 days later
    vm.warp(block.timestamp + 5 days);

    // Set DAI strategy again with a new strategy
    MockStrategy mockDaiVaultStrategy2 = new MockStrategy(
      address(dai),
      mockDaiVault,
      address(poolDiamond)
    );
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy2);

    // The following conditions should be met:
    // 1. The strategy is in pending state
    // 2. DAI's strategy startTimestamp should be block.timestamp + 1 weeks
    // 3. DAI's strategy principle should be 0
    // 4. DAI's strategy target bps should be 0
    strategyData = poolGetterFacet.strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(mockDaiVaultStrategy2)
    );
    assertEq(strategyData.startTimestamp, block.timestamp + 1 weeks);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 0);
  }

  function testCorrectness_WhenReplaceActiveStrategy_WhenActiveStrategyIsProfit()
    external
  {
    // Set DAI strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // The following conditions should be met:
    // 1. The strategy is in pending state
    // 2. DAI's strategy startTimestamp should be block.timestamp + 1 weeks
    // 3. DAI's strategy principle should be 0
    // 4. DAI's strategy target bps should be 0
    LibPoolConfigV1.StrategyData memory strategyData = poolGetterFacet
      .strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(mockDaiVaultStrategy)
    );
    assertEq(strategyData.startTimestamp, block.timestamp + 1 weeks);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 0);

    // Set DAI's strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // The following condition should be met:
    // 1. DAI's strategy target bps should be 50%
    strategyData = poolGetterFacet.strategyDataOf(address(dai));
    assertEq(strategyData.targetBps, 5000);

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

    // Warp to 1 week later
    vm.warp(block.timestamp + 1 weeks);

    // Commit the strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // The following conditions should be met:
    // 1. DAI's pending strategy should be address(0)
    // 2. DAI's strategy should be mockDaiVaultStrategy
    // 3. DAI's strategy startTimestamp should be 0
    // 4. DAI's strategy principle should be 0
    // 5. DAI's strategy target bps should be 0
    strategyData = poolGetterFacet.strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(0)
    );
    assertEq(
      address(poolGetterFacet.strategyOf(address(dai))),
      address(mockDaiVaultStrategy)
    );
    assertEq(strategyData.startTimestamp, 0);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 5000);

    // Call farm to yield farm 997 * 50% = 498.5 DAI
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
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);

    // Mint 1000 DAI to the vault to make it profitable
    dai.mint(address(mockDaiVault), 1000 * 10**18);

    // The following conditions should be met:
    // 1. DAI's strategy delta should be: +1000 DAI
    // 2. DAI's strategy should be profitable
    // 2. Pool's aum by min price should be:
    // = 997 * 1 + 1000 [StrategyDelta]
    // = 1997 USD
    // 3. Pool's aum by max price should be:
    // = 997 * 1 + 1000 [StrategyDelta]
    // = 1997 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 1000 * 10**18);
    assertTrue(isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 1997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 1997 * 10**18);

    // Replace the strategy with mockDaiVaultStrategy2
    MockStrategy mockDaiVaultStrategy2 = new MockStrategy(
      address(dai),
      mockDaiVault,
      address(poolDiamond)
    );
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy2);
    vm.warp(block.timestamp + 1 weeks);
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy2);

    // The following conditions should be met:
    // 1. DAI's strategy should be mockDaiVaultStrategy2
    // 2. DAI's strategy delta should be: 0
    // 3. DAI's liquidity should be 1997 DAI
    // 4. DAI's strategy principle should be 0
    // 5. Pool's aum by min price should be:
    // = 1997 * 1 + 0 [StrategyDelta]
    // = 1997 USD
    // 6. Pool's aum by max price should be:
    // = 1997 * 1 + 0 [StrategyDelta]
    // = 1997 USD
    assertEq(
      address(poolGetterFacet.strategyOf(address(dai))),
      address(mockDaiVaultStrategy2)
    );
    (isProfit, strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 0);
    assertTrue(!isProfit);
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 1997 * 10**18);
    assertEq(poolGetterFacet.strategyDataOf(address(dai)).principle, 0);
    assertEq(poolGetterFacet.getAumE18(false), 1997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 1997 * 10**18);
  }

  function testCorrectness_WhenReplaceActiveStrategy_WhenActiveStrategyIsLoss()
    external
  {
    // Set DAI strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // The following conditions should be met:
    // 1. The strategy is in pending state
    // 2. DAI's strategy startTimestamp should be block.timestamp + 1 weeks
    // 3. DAI's strategy principle should be 0
    // 4. DAI's strategy target bps should be 0
    LibPoolConfigV1.StrategyData memory strategyData = poolGetterFacet
      .strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(mockDaiVaultStrategy)
    );
    assertEq(strategyData.startTimestamp, block.timestamp + 1 weeks);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 0);

    // Set DAI's strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(address(dai), 5000);

    // The following condition should be met:
    // 1. DAI's strategy target bps should be 50%
    strategyData = poolGetterFacet.strategyDataOf(address(dai));
    assertEq(strategyData.targetBps, 5000);

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

    // Warp to 1 week later
    vm.warp(block.timestamp + 1 weeks);

    // Commit the strategy
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy);

    // The following conditions should be met:
    // 1. DAI's pending strategy should be address(0)
    // 2. DAI's strategy should be mockDaiVaultStrategy
    // 3. DAI's strategy startTimestamp should be 0
    // 4. DAI's strategy principle should be 0
    // 5. DAI's strategy target bps should be 0
    strategyData = poolGetterFacet.strategyDataOf(address(dai));
    assertEq(
      address(poolGetterFacet.pendingStrategyOf(address(dai))),
      address(0)
    );
    assertEq(
      address(poolGetterFacet.strategyOf(address(dai))),
      address(mockDaiVaultStrategy)
    );
    assertEq(strategyData.startTimestamp, 0);
    assertEq(strategyData.principle, 0);
    assertEq(strategyData.targetBps, 5000);

    // Call farm to yield farm 997 * 50% = 498.5 DAI
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
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 997 * 10**18);
    assertEq(
      poolGetterFacet.strategyDataOf(address(dai)).principle,
      498.5 * 10**18
    );
    assertEq(poolGetterFacet.getAumE18(false), 997 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 997 * 10**18);

    // Assuming the strategy loss 200 DAI
    dai.burn(address(mockDaiVault), 200 * 10**18);

    // The following conditions should be met:
    // 1. DAI's strategy delta should be: -200 DAI
    // 2. DAI's strategy should be loss
    // 2. Pool's aum by min price should be:
    // = 997 * 1 - 200 [StrategyDelta]
    // = 797 USD
    // 3. Pool's aum by max price should be:
    // = 997 * 1 + 200 [StrategyDelta]
    // = 797 USD
    (bool isProfit, uint256 strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 200 * 10**18);
    assertTrue(!isProfit);
    assertEq(poolGetterFacet.getAumE18(false), 797 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 797 * 10**18);

    // Replace the strategy with mockDaiVaultStrategy2
    MockStrategy mockDaiVaultStrategy2 = new MockStrategy(
      address(dai),
      mockDaiVault,
      address(poolDiamond)
    );
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy2);
    vm.warp(block.timestamp + 1 weeks);
    poolFarmFacet.setStrategyOf(address(dai), mockDaiVaultStrategy2);

    // The following conditions should be met:
    // 1. DAI's strategy should be mockDaiVaultStrategy2
    // 2. DAI's strategy delta should be: 0
    // 3. DAI's liquidity should be 797 DAI
    // 4. DAI's strategy principle should be 0
    // 5. Pool's aum by min price should be:
    // = 797 * 1 + 0 [StrategyDelta]
    // = 797 USD
    // 6. Pool's aum by max price should be:
    // = 797 * 1 + 0 [StrategyDelta]
    // = 797 USD
    assertEq(
      address(poolGetterFacet.strategyOf(address(dai))),
      address(mockDaiVaultStrategy2)
    );
    (isProfit, strategyDelta) = poolGetterFacet.getStrategyDeltaOf(
      address(dai)
    );
    assertEq(strategyDelta, 0);
    assertTrue(!isProfit);
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 797 * 10**18);
    assertEq(poolGetterFacet.strategyDataOf(address(dai)).principle, 0);
    assertEq(poolGetterFacet.getAumE18(false), 797 * 10**18);
    assertEq(poolGetterFacet.getAumE18(true), 797 * 10**18);
  }
}
