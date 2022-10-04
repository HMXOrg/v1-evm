// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolDiamond_BaseTest, LibPoolConfigV1, Pool, stdError, console, GetterFacetInterface, LiquidityFacetInterface } from "./PoolDiamond_BaseTest.t.sol";

contract PoolDiamond_SwapTest is PoolDiamond_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens2,
      LibPoolConfigV1.TokenConfig[] memory tokenConfigs2
    ) = buildDefaultSetTokenConfigInput2();

    poolAdminFacet.setTokenConfigs(tokens2, tokenConfigs2);
  }

  function testRevert_WhenTokenInIsRandomErc20() external {
    vm.expectRevert(abi.encodeWithSignature("LiquidityFacet_BadTokenIn()"));
    poolLiquidityFacet.swap(
      address(this),
      address(randomErc20),
      address(dai),
      0,
      address(this)
    );
  }

  function testRevert_WhenTokenOutIsRandomErc20() external {
    vm.expectRevert(abi.encodeWithSignature("LiquidityFacet_BadTokenOut()"));
    poolLiquidityFacet.swap(
      address(this),
      address(dai),
      address(randomErc20),
      0,
      address(this)
    );
  }

  function testRevert_WhenSwapIsDisabled() external {
    // Disable Swap
    poolAdminFacet.setIsSwapEnable(false);

    vm.expectRevert(abi.encodeWithSignature("LiquidityFacet_SwapDisabled()"));
    poolLiquidityFacet.swap(
      address(this),
      address(dai),
      address(wbtc),
      0,
      address(this)
    );
  }

  function testRevert_WhenTokenInTokenOutSame() external {
    vm.expectRevert(
      abi.encodeWithSignature("LiquidityFacet_SameTokenInTokenOut()")
    );
    poolLiquidityFacet.swap(
      address(this),
      address(dai),
      address(dai),
      0,
      address(this)
    );
  }

  function testRevert_WhenAmountInZero() external {
    vm.expectRevert(abi.encodeWithSignature("LiquidityFacet_BadAmount()"));
    poolLiquidityFacet.swap(
      address(this),
      address(dai),
      address(wbtc),
      0,
      address(this)
    );
  }

  function testRevert_WhenOverUsdDebtCeiling() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    dai.mint(address(this), 200000 ether);
    wbtc.mint(address(this), 10 ether);

    // Perform add liquidity
    dai.approve(address(poolRouter), 200000 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(dai),
      200000 ether,
      address(this),
      0
    );

    wbtc.approve(address(poolRouter), 10 ether);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(wbtc),
      10 ether,
      address(this),
      0
    );

    // Set DAI's debt ceiling to be 200100 USD
    address[] memory tokens = new address[](1);
    tokens[0] = address(dai);
    LibPoolConfigV1.TokenConfig[]
      memory tokenConfigs = new LibPoolConfigV1.TokenConfig[](1);
    tokenConfigs[0] = LibPoolConfigV1.TokenConfig({
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
    poolAdminFacet.setTokenConfigs(tokens, tokenConfigs);

    // Mint more DAI
    dai.mint(address(this), 701 ether);
    dai.approve(address(poolRouter), 701 ether);

    // Try to swap that will exceed the debt ceiling
    vm.expectRevert(abi.encodeWithSignature("LibPoolV1_OverUsdDebtCeiling()"));
    poolRouter.swap(
      address(poolDiamond),
      address(dai),
      address(wbtc),
      701 ether,
      0,
      address(this)
    );
  }

  function testRevert_WhenLiquidityLessThanBuffer() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    dai.mint(address(this), 200000 ether);
    wbtc.mint(address(this), 10 ether);

    dai.approve(address(poolDiamond), type(uint256).max);
    wbtc.approve(address(poolDiamond), type(uint256).max);

    // Perform add liquidity
    dai.approve(address(poolRouter), 200000 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(dai),
      200000 ether,
      address(this),
      0
    );
    wbtc.approve(address(poolRouter), 10 * 10**8);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(wbtc),
      10 * 10**8,
      address(this),
      0
    );

    // Set WBTC's liquidity buffer to be 9.97 WBTC
    address[] memory tokens = new address[](1);
    tokens[0] = address(wbtc);
    LibPoolConfigV1.TokenConfig[]
      memory tokenConfigs = new LibPoolConfigV1.TokenConfig[](1);
    tokenConfigs[0] = LibPoolConfigV1.TokenConfig({
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
    poolAdminFacet.setTokenConfigs(tokens, tokenConfigs);

    dai.mint(address(this), 1 ether);
    dai.approve(address(poolRouter), 1 ether);

    vm.expectRevert(
      abi.encodeWithSignature("LiquidityFacet_LiquidityBuffer()")
    );
    poolRouter.swap(
      address(poolDiamond),
      address(dai),
      address(wbtc),
      1 ether,
      0,
      address(this)
    );
  }

  function testCorrectness_WhenSwapSuccess() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    matic.mint(ALICE, 200 ether);
    wbtc.mint(ALICE, 1 * 10**8);

    // ------- Alice session START -------
    vm.startPrank(ALICE);

    // Alice add liquidity 200 MATIC (~$60,000)
    matic.approve(address(poolRouter), 200 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(matic),
      200 ether,
      ALICE,
      0
    );

    // Alice add 200 MATIC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 200 * (1-0.003) * 300 = 59820 USD in AUM
    assertEq(poolGetterFacet.getAumE18(false), 59820 ether);

    // Alice add liquidity 1 WBTC (~$60,000)
    wbtc.approve(address(poolRouter), 1 * 10**8);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(wbtc),
      1 * 10**8,
      ALICE,
      0
    );

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
    assertEq(
      poolGetterFacet.plp().balanceOf(address(plpStaking)),
      119640 ether
    );
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

    // ------- Bob session START -------
    vm.startPrank(BOB);

    // Bob swap 100 MATIC for WBTC
    matic.approve(address(poolRouter), 100 ether);
    poolRouter.swap(
      address(poolDiamond),
      address(matic),
      address(wbtc),
      100 ether,
      0,
      BOB
    );

    // After Bob swap, the following condition is expected:
    // 1. Pool should have 159520 + (100 * 400) - ((100 * 400 / 100000) * 80000) = 167520 USD in AUM
    // 2. Bob should get (100 * 400 / 100000) * (1 - 0.003) = 0.3988 WBTC
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make (1 * 0.003) + ((100 * 400 / 100000) * 0.003) = 0.0042 WBTC in fee
    // 5. USD debt for MATIC should be 59820 + (100 * 400) = 99820 USD
    // 6. USD debt for WBTC should be 59820 - (100 * 400) = 19820 USD
    // 7. Pool's MATIC liquidity should be 199.4 + 100 = 299.4 MATIC
    // 8. Pool's WBTC liquidity should be 0.997 - ((100 * 400 / 100000)) = 0.597 WBTC
    assertEq(poolGetterFacet.getAumE18(false), 167520 ether);
    assertEq(wbtc.balanceOf(BOB), 0.3988 * 10**8);
    assertEq(poolGetterFacet.feeReserveOf(address(matic)), 0.6 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 0.0042 * 10**8);
    assertEq(poolGetterFacet.usdDebtOf(address(matic)), 99820 ether);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 19820 ether);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 299.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.597 * 10**8);

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

    plpStaking.withdraw(
      address(poolGetterFacet.plp()),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );

    poolGetterFacet.plp().approve(
      address(poolRouter),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(matic),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false),
      ALICE,
      0
    );

    assertEq(poolGetterFacet.plp().balanceOf(address(poolDiamond)), 0);

    // Alice expected to get 50000 / 500 * (1-0.003) = 99.7 MATIC
    assertEq(matic.balanceOf(ALICE), 99699999999999999999);

    // Alice remove 50000 USD worth of PLP from the pool with WBTC as tokenOut
    plpStaking.withdraw(
      address(poolGetterFacet.plp()),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );

    poolGetterFacet.plp().approve(
      address(poolRouter),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(wbtc),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false),
      ALICE,
      0
    );

    // Alice expected to get 50000 / 100000 * (1-0.003) = 0.4985 WBTC
    assertEq(wbtc.balanceOf(ALICE), 49849999);

    // Alice try remove 10000 USD worth of PLP from the pool with WBTC as tokenOut
    // Pool doesn't has any liquidity left, so this should revert
    uint256 plpNeeded = (10_000 ether * poolGetterFacet.plp().totalSupply()) /
      poolGetterFacet.getAumE18(false);

    plpStaking.withdraw(address(poolGetterFacet.plp()), plpNeeded);

    poolGetterFacet.plp().approve(address(poolRouter), plpNeeded);
    vm.expectRevert(stdError.arithmeticError);
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(wbtc),
      plpNeeded,
      ALICE,
      0
    );
  }

  function testRevert_Slippage() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    matic.mint(ALICE, 200 ether);
    wbtc.mint(ALICE, 1 * 10**8);

    // ------- Alice session START -------
    vm.startPrank(ALICE);

    // Alice add liquidity 200 MATIC (~$60,000)
    matic.approve(address(poolRouter), 200 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(matic),
      200 ether,
      ALICE,
      0
    );

    // Alice add 200 MATIC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 200 * (1-0.003) * 300 = 59820 USD in AUM
    assertEq(poolGetterFacet.getAumE18(false), 59820 ether);

    // Alice add liquidity 1 WBTC (~$60,000)
    wbtc.approve(address(poolRouter), 1 * 10**8);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(wbtc),
      1 * 10**8,
      ALICE,
      0
    );

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
    assertEq(
      poolGetterFacet.plp().balanceOf(address(plpStaking)),
      119640 ether
    );
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

    // ------- Bob session START -------
    vm.startPrank(BOB);

    // Bob swap 100 MATIC for WBTC
    // After Bob swap, the following condition is expected:
    // 1. Pool should have 159520 + (100 * 400) - ((100 * 400 / 100000) * 80000) = 167520 USD in AUM
    // 2. Bob should get (100 * 400 / 100000) * (1 - 0.003) = 0.3988 WBTC
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make (1 * 0.003) + ((100 * 400 / 100000) * 0.003) = 0.0042 WBTC in fee
    // 5. USD debt for MATIC should be 59820 + (100 * 400) = 99820 USD
    // 6. USD debt for WBTC should be 59820 - (100 * 400) = 19820 USD
    // 7. Pool's MATIC liquidity should be 199.4 + 100 = 299.4 MATIC
    // 8. Pool's WBTC liquidity should be 0.997 - ((100 * 400 / 100000)) = 0.597 WBTC
    matic.approve(address(poolRouter), 100 ether);
    vm.expectRevert(abi.encodeWithSignature("LiquidityFacet_Slippage()"));
    poolRouter.swap(
      address(poolDiamond),
      address(matic),
      address(wbtc),
      100 ether,
      40000000,
      BOB
    );
  }

  function testCorrectness_WhenSwapSuccess_NativeIn() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    vm.deal(ALICE, 200 ether);
    wbtc.mint(ALICE, 1 * 10**8);

    // ------- Alice session START -------
    vm.startPrank(ALICE);
    plp.approve(address(poolRouter), type(uint256).max);
    // Alice add liquidity 200 MATIC (~$60,000)
    poolRouter.addLiquidityNative{ value: 200 ether }(
      address(poolDiamond),
      address(matic),
      ALICE,
      0
    );

    // Alice add 200 MATIC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 200 * (1-0.003) * 300 = 59820 USD in AUM
    assertEq(poolGetterFacet.getAumE18(false), 59820 ether);

    // Alice add liquidity 1 WBTC (~$60,000)
    wbtc.approve(address(poolRouter), 1 * 10**8);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(wbtc),
      1 * 10**8,
      ALICE,
      0
    );

    // Alice add another 1 WBTC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 59,820 + (1 * (1-0.003) * 60000) = 119,640 USD in AUM
    // 2. PLP staking contract should have 119,640 PLP
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make 1 * 0.003 = 0.003 WBTC in fee
    // 5. USD debt for MATIC should be 59,820 USD
    // 6. USD debt for WBTC should be 59,820 USD
    // 7. Pool's MATIC liquidity should be 200 * (1-0.003) = 199.4 MATIC
    // 8. Pool's WBTC liquidity should be 1 * (1-0.003) = 0.997 WBTC
    assertEq(poolGetterFacet.getAumE18(false), 119640 ether);
    assertEq(
      poolGetterFacet.plp().balanceOf(address(plpStaking)),
      119640 ether
    );
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

    vm.deal(BOB, 100 ether);

    // ------- Bob session START -------
    vm.startPrank(BOB);

    // Bob swap 100 MATIC for WBTC
    poolRouter.swapNative{ value: 100 ether }(
      address(poolDiamond),
      address(matic),
      address(wbtc),
      100 ether,
      0,
      BOB
    );

    // After Bob swap, the following condition is expected:
    // 1. Pool should have 159520 + (100 * 400) - ((100 * 400 / 100000) * 80000) = 167520 USD in AUM
    // 2. Bob should get (100 * 400 / 100000) * (1 - 0.003) = 0.3988 WBTC
    // 3. Pool should make 200 * 0.003 = 0.6 MATIC in fee
    // 4. Pool should make (1 * 0.003) + ((100 * 400 / 100000) * 0.003) = 0.0042 WBTC in fee
    // 5. USD debt for MATIC should be 59820 + (100 * 400) = 99820 USD
    // 6. USD debt for WBTC should be 59820 - (100 * 400) = 19820 USD
    // 7. Pool's MATIC liquidity should be 199.4 + 100 = 299.4 MATIC
    // 8. Pool's WBTC liquidity should be 0.997 - ((100 * 400 / 100000)) = 0.597 WBTC
    assertEq(poolGetterFacet.getAumE18(false), 167520 ether);
    assertEq(wbtc.balanceOf(BOB), 0.3988 * 10**8);
    assertEq(poolGetterFacet.feeReserveOf(address(matic)), 0.6 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 0.0042 * 10**8);
    assertEq(poolGetterFacet.usdDebtOf(address(matic)), 99820 ether);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 19820 ether);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 299.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 0.597 * 10**8);

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

    plpStaking.withdraw(
      address(poolGetterFacet.plp()),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );

    assertEq(
      poolGetterFacet.plp().balanceOf(address(ALICE)),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );

    poolGetterFacet.plp().approve(
      address(poolRouter),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );
    poolRouter.removeLiquidityNative(
      address(poolDiamond),
      address(matic),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false),
      ALICE,
      0
    );

    assertEq(poolGetterFacet.plp().balanceOf(address(poolDiamond)), 0);

    // Alice expected to get 50000 / 500 * (1-0.003) = 99.7 MATIC
    assertEq(address(ALICE).balance, 99699999999999999999);

    // Alice remove 50000 USD worth of PLP from the pool with WBTC as tokenOut

    plpStaking.withdraw(
      address(poolGetterFacet.plp()),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );

    poolGetterFacet.plp().approve(
      address(poolRouter),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false)
    );
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(wbtc),
      (50_000 ether * poolGetterFacet.plp().totalSupply()) /
        poolGetterFacet.getAumE18(false),
      ALICE,
      0
    );

    // Alice expected to get 50000 / 100000 * (1-0.003) = 0.4985 WBTC
    assertEq(wbtc.balanceOf(ALICE), 49849999);

    // Alice try remove 10000 USD worth of PLP from the pool with WBTC as tokenOut
    // Pool doesn't has any liquidity left, so this should revert
    uint256 plpNeeded = (10_000 ether * poolGetterFacet.plp().totalSupply()) /
      poolGetterFacet.getAumE18(false);

    plpStaking.withdraw(address(poolGetterFacet.plp()), plpNeeded);

    poolGetterFacet.plp().approve(address(poolRouter), plpNeeded);
    vm.expectRevert(stdError.arithmeticError);
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(wbtc),
      plpNeeded,
      ALICE,
      0
    );
  }

  function testCorrectness_WhenSwapSuccess_NativeOut() external {
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    vm.deal(ALICE, 200 ether);
    wbtc.mint(ALICE, 1 * 10**8);

    // ------- Alice session START -------
    vm.startPrank(ALICE);
    plp.approve(address(poolRouter), type(uint256).max);

    // Alice add liquidity 200 MATIC (~$60,000)
    poolRouter.addLiquidityNative{ value: 200 ether }(
      address(poolDiamond),
      address(matic),
      ALICE,
      0
    );

    // Alice add 200 MATIC as liquidity to the pool, the following condition is expected:
    // 1. Pool should have 200 * (1-0.003) * 300 = 59820 USD in AUM
    assertEq(poolGetterFacet.getAumE18(false), 59820 ether);

    // Alice add liquidity 1 WBTC (~$60,000)
    wbtc.approve(address(poolRouter), 1 * 10**8);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(wbtc),
      1 * 10**8,
      ALICE,
      0
    );

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
    assertEq(
      poolGetterFacet.plp().balanceOf(address(plpStaking)),
      119640 ether
    );
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

    wbtc.mint(BOB, 0.0075 * 10**8);

    // ------- Bob session START -------
    vm.startPrank(BOB);

    // Bob swap 0.0075 WBTC for MATIC
    wbtc.approve(address(poolRouter), 0.0075 * 10**8);
    poolRouter.swapNative{ value: 0 ether }(
      address(poolDiamond),
      address(wbtc),
      address(matic),
      0.0075 * 10**8,
      0,
      BOB
    );

    // After Bob swap, the following condition is expected:
    // 1. Pool should have
    // = initialLiquidity - maticOutUSDValue + wbtcInUSDValue
    // = 159520 - (1 * 400) + (0.0075 * 80000) = 159720 USD in AUM
    // 2. Bob should get (0.0075 * 80000 / 600) * (1 - 0.003) = 0.997 MATIC
    // 3. Pool should make (200 * 0.003) + ((0.0075 * 80000 / 600) * 0.003) = 0.603 MATIC in fee
    // 4. Pool should make (1 * 0.003) = 0.003 WBTC in fee
    // 5. USD debt for MATIC should be 59820 - (1 * 600) = 59220 USD
    // 6. USD debt for WBTC should be 59820 + (1 * 600) = 60420 USD
    // 7. Pool's MATIC liquidity should be 199.4 - 1 = 198.4 MATIC
    // 8. Pool's WBTC liquidity should be 0.997 + 0.0075 = 1.0045 WBTC
    assertEq(poolGetterFacet.getAumE18(false), 159720 ether);
    assertEq(address(BOB).balance, 0.997 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(matic)), 0.603 ether);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 0.003 * 10**8);
    assertEq(poolGetterFacet.usdDebtOf(address(matic)), 59220 ether);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 60420 ether);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 198.4 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 1.0045 * 10**8);

    vm.stopPrank();
  }
}
