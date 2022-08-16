// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Pool_BaseTest, PoolConfig, stdError, console } from "./Pool_BaseTest.t.sol";

contract Pool_SwapTest is Pool_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory tokenConfigs
    ) = buildDefaultSetTokenConfigInput();

    poolConfig.setTokenConfigs(tokens, tokenConfigs);
  }

  function testRevert_WhenTokenInIsRandomErc20() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_BadArgument()"));
    pool.swap(address(randomErc20), address(dai), 1, 0, address(this));
  }

  function testRevert_WhenTokenOutIsRandomErc20() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_BadArgument()"));
    pool.swap(address(dai), address(randomErc20), 1, 0, address(this));
  }

  function testRevert_WhenSwapIsDisabled() external {
    // Disable Swap
    pool.config().setIsSwapEnable(false);

    vm.expectRevert(abi.encodeWithSignature("Pool_SwapDisabled()"));
    pool.swap(address(dai), address(wbtc), 1, 0, address(this));
  }

  function testRevert_WhenTokenInTokenOutSame() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_BadArgument()"));
    pool.swap(address(dai), address(dai), 1, 0, address(this));
  }

  function testRevert_WhenAmountInZero() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_BadArgument()"));
    pool.swap(address(dai), address(wbtc), 0, 0, address(this));
  }

  function testRevert_WhenOverUsdDebtCeiling() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    dai.mint(address(this), 200000 ether);
    wbtc.mint(address(this), 10 ether);

    dai.approve(address(pool), type(uint256).max);
    wbtc.approve(address(pool), type(uint256).max);

    // Perform add liquidity
    pool.addLiquidity(address(dai), 200000 ether, address(this), 199400 ether);
    pool.addLiquidity(address(wbtc), 10 ether, address(this), 598200 ether);

    // Set DAI's debt ceiling to be 200100 USD
    address[] memory tokens = new address[](1);
    tokens[0] = address(dai);
    PoolConfig.TokenConfig[] memory tokenConfigs = new PoolConfig.TokenConfig[](
      1
    );
    tokenConfigs[0] = PoolConfig.TokenConfig({
      accept: true,
      isStable: true,
      isShortable: false,
      decimals: dai.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 200100 ether,
      shortCeiling: 0,
      bufferLiquidity: 0
    });
    poolConfig.setTokenConfigs(tokens, tokenConfigs);

    // Mint more DAI
    dai.mint(address(this), 701 ether);

    // Try to swap that will exceed the debt ceiling
    vm.expectRevert(abi.encodeWithSignature("Pool_OverUsdDebtCeiling()"));
    pool.swap(address(dai), address(wbtc), 701 ether, 0, address(this));
  }

  function testRevert_WhenLiquidityLessThanBuffer() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    dai.mint(address(this), 200000 ether);
    wbtc.mint(address(this), 10 ether);

    dai.approve(address(pool), type(uint256).max);
    wbtc.approve(address(pool), type(uint256).max);

    // Perform add liquidity
    pool.addLiquidity(address(dai), 200000 ether, address(this), 199400 ether);
    pool.addLiquidity(address(wbtc), 10 * 10**8, address(this), 598200 ether);

    // Set WBTC's liquidity buffer to be 9.97 WBTC
    address[] memory tokens = new address[](1);
    tokens[0] = address(wbtc);
    PoolConfig.TokenConfig[] memory tokenConfigs = new PoolConfig.TokenConfig[](
      1
    );
    tokenConfigs[0] = PoolConfig.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: wbtc.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 9.97 * 10**8
    });
    poolConfig.setTokenConfigs(tokens, tokenConfigs);

    dai.mint(address(this), 1 ether);

    vm.expectRevert(abi.encodeWithSignature("Pool_LiquidityBuffer()"));
    pool.swap(address(dai), address(wbtc), 1 ether, 0, address(this));
  }

  function testCorrectness_WhenSwapSuccess() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    matic.mint(ALICE, 200 ether);
    wbtc.mint(ALICE, 1 * 10**8);

    // ------- Alice session START -------
    vm.startPrank(ALICE);

    matic.approve(address(pool), type(uint256).max);
    wbtc.approve(address(pool), type(uint256).max);

    // Alice add liquidity 200 MATIC (~$60,000)
    pool.addLiquidity(address(matic), 200 ether, ALICE, 59820 ether);

    // Alice add 200 MATIC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 200 * (1-0.003) * 300 = 59820 USD in AUM
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 59820 ether);

    // Alice add liquidity 1 WBTC (~$60,000)
    pool.addLiquidity(address(wbtc), 1 * 10**8, ALICE, 59820 ether);

    // Alice add another 1 WBTC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 59,820 + (1 * (1-0.003) * 60000) = 119,640 USD in AUM
    // 2. Alice should have 119,640 PLP
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make 1 * 0.003 = 0.003 WBTC in fee
    // 5. USD debt for MATIC should be 59,820 USD
    // 6. USD debt for WBTC should be 59,820 USD
    // 7. Pool's MATIC liquidity should be 200 * (1-0.003) = 199.4 MATIC
    // 8. Pool's WBTC liquidity should be 1 * (1-0.003) = 0.997 WBTC
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 119640 ether);
    assertEq(pool.plp().balanceOf(ALICE), 119640 ether);
    assertEq(pool.feeReserveOf(address(matic)), 0.6 ether);
    assertEq(pool.feeReserveOf(address(wbtc)), 300000);
    assertEq(pool.usdDebtOf(address(matic)), 59820 ether);
    assertEq(pool.usdDebtOf(address(wbtc)), 59820 ether);
    assertEq(pool.liquidityOf(address(matic)), 199.4 ether);
    assertEq(pool.liquidityOf(address(wbtc)), 0.997 * 10**8);

    vm.stopPrank();
    // ------- Alice session END -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(600 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);

    // Oracle price updates, the following condition is expected:
    // 1. Pool should have (199.4 * 400) + (0.997 * 60000) = 139,580 USD
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 139580 ether);

    wbtcPriceFeed.setLatestAnswer(90000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(100000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(80000 * 10**8);

    // Oracle price updates, the following condition is expected:
    // 1. Pool should have (199.4 * 400) + (0.997 * 80000) = 159,520 USD
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 159520 ether);

    matic.mint(BOB, 100 ether);

    // ------- Bob session START -------
    vm.startPrank(BOB);

    matic.approve(address(pool), type(uint256).max);

    // Bob swap 100 MATIC for WBTC
    pool.swap(address(matic), address(wbtc), 100 ether, 0, BOB);

    // After Bob swap, the following condition is expected:
    // 1. Pool should have 159520 + (100 * 400) - ((100 * 400 / 100000) * 80000) = 167520 USD in AUM
    // 2. Bob should get (100 * 400 / 100000) * (1 - 0.003) = 0.3988 WBTC
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make (1 * 0.003) + ((100 * 400 / 100000) * 0.003) = 0.0042 WBTC in fee
    // 5. USD debt for MATIC should be 59820 + (100 * 400) = 99820 USD
    // 6. USD debt for WBTC should be 59820 - (100 * 400) = 19820 USD
    // 7. Pool's MATIC liquidity should be 199.4 + 100 = 299.4 MATIC
    // 8. Pool's WBTC liquidity should be 0.997 - ((100 * 400 / 100000)) = 0.597 WBTC
    assertEq(pool.poolMath().getAum18(pool, MinMax.MIN), 167520 ether);
    assertEq(wbtc.balanceOf(BOB), 0.3988 * 10**8);
    assertEq(pool.feeReserveOf(address(matic)), 0.6 ether);
    assertEq(pool.feeReserveOf(address(wbtc)), 0.0042 * 10**8);
    assertEq(pool.usdDebtOf(address(matic)), 99820 ether);
    assertEq(pool.usdDebtOf(address(wbtc)), 19820 ether);
    assertEq(pool.liquidityOf(address(matic)), 299.4 ether);
    assertEq(pool.liquidityOf(address(wbtc)), 0.597 * 10**8);

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
    pool.removeLiquidity(
      address(matic),
      (50_000 ether * pool.plp().totalSupply()) /
        pool.poolMath().getAum18(pool, MinMax.MIN),
      ALICE,
      99.7 ether
    );

    // Alice expected to get 50000 / 500 * (1-0.003) = 99.7 MATIC
    assertEq(matic.balanceOf(ALICE), 99.7 ether);

    // Alice remove 50000 USD worth of PLP from the pool with WBTC as tokenOut
    pool.removeLiquidity(
      address(wbtc),
      (50_000 ether * pool.plp().totalSupply()) /
        pool.poolMath().getAum18(pool, MinMax.MIN),
      ALICE,
      0.4985 * 10**8
    );

    // Alice expected to get 50000 / 100000 * (1-0.003) = 0.4985 WBTC
    assertEq(wbtc.balanceOf(ALICE), 0.4985 * 10**8);

    // Alice try remove 10000 USD worth of PLP from the pool with WBTC as tokenOut
    // Pool doesn't has any liquidity left, so this should revert
    uint256 plpNeeded = (10_000 ether * pool.plp().totalSupply()) /
      pool.poolMath().getAum18(pool, MinMax.MIN);
    vm.expectRevert(stdError.arithmeticError);
    pool.removeLiquidity(address(wbtc), plpNeeded, ALICE, 0);
  }
}
