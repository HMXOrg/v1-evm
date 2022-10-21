// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolDiamond_BaseTest, LibPoolConfigV1, console, GetterFacetInterface, LiquidityFacetInterface, PoolRouter } from "./PoolDiamond_BaseTest.t.sol";
import { PLP } from "solidity/contracts/tokens/PLP.sol";

contract PoolDiamond_RemoveLiquidityTest is PoolDiamond_BaseTest {
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
  }

  function testRevert_WhenTryToAddLiquidityUnderOtherAccount() external {
    vm.expectRevert(abi.encodeWithSignature("LibPoolV1_ForbiddenPlugin()"));
    poolLiquidityFacet.removeLiquidity(ALICE, address(dai), address(this));
  }

  function testRevert_WhenAmountOutZero() external {
    dai.mint(address(this), 100 ether);

    dai.approve(address(poolRouter), 100 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(dai),
      100 ether,
      address(this),
      0
    );

    vm.expectRevert(abi.encodeWithSignature("LiquidityFacet_BadAmount()"));
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(dai),
      0,
      address(this),
      0
    );
  }

  function testRevert_WhenCoolDownNotPassed() external {
    dai.mint(address(this), 100 ether);

    dai.approve(address(poolRouter), 100 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(dai),
      100 ether,
      address(this),
      0
    );

    poolGetterFacet.plp().approve(address(poolRouter), 1);

    vm.expectRevert(abi.encodeWithSelector(PLP.PLP_Cooldown.selector, 86401));
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(dai),
      1,
      address(this),
      0
    );
  }

  function testCorrectness_WhenDynamicFeeOff() external {
    // Mint 100 DAI to Alice
    dai.mint(ALICE, 100 ether);

    // ------- Alice session -------
    // Alice as a liquidity provider for DAI
    vm.startPrank(ALICE);

    // Perform add liquidity
    dai.approve(address(poolRouter), 100 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(dai),
      100 ether,
      ALICE,
      0
    );

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

    // Perform add liquidity
    matic.approve(address(poolRouter), 1 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(matic),
      1 ether,
      BOB,
      0
    );

    vm.stopPrank();
    // ------- Finish Bob session -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    assertEq(poolGetterFacet.getAumE18(true), 598.2 ether);
    assertEq(poolGetterFacet.getAumE18(false), 498.5 ether);

    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    // Mint 0.01 WBTC (600 USD) to CAT.
    wbtc.mint(CAT, 1000000);
    vm.warp(block.timestamp + 1 days);

    // ------- Cat session -------
    vm.startPrank(CAT);
    wbtc.approve(address(poolRouter), type(uint256).max);

    // Perform add liquidity
    wbtc.approve(address(poolRouter), 1000000);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(wbtc),
      1000000,
      CAT,
      0
    );

    vm.stopPrank();
    // ------- Finish Cat session -------

    assertEq(poolGetterFacet.totalUsdDebt(), 997 ether);

    // Warp so that the cool down is passed.
    vm.warp(block.timestamp + 1 days + 1);

    // ------- Alice session -------
    vm.startPrank(ALICE);

    // Perform remove liquidity
    poolGetterFacet.plp().approve(address(poolRouter), 72 ether);
    plpStaking.withdraw(address(poolGetterFacet.plp()), 99.7 ether);
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(dai),
      72 ether,
      ALICE,
      0
    );

    // Alice remove 72 PLP, the following criteria needs to statisfy:
    // 1. Alice should get ((72 * 1096.7) / 797.6) * (1-0.003) / 1 ~= 98.703 DAI
    // 2. Alice should have 99.7 - 72 = 27.7 PLP
    assertEq(dai.balanceOf(ALICE), 98703000000000000000);
    assertEq(poolGetterFacet.plp().balanceOf(ALICE), 27.7 ether);

    // Alice remove 27.7 PLP to MATIC
    poolGetterFacet.plp().approve(address(poolRouter), 27.7 ether);
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(matic),
      27.7 ether,
      ALICE,
      0
    );

    // Alice remove 27.7 PLP, the following criteria needs to statisfy:
    // 1. Alice should get ((27.7 * 997.7) / 725.6) * (1-0.003) / 500 ~= 0.0759 MATIC
    // 2. Alice should have 27.7 - 27.7 = 0 PLP
    // 3. PLP's total supply should be 725.6 - 27.7 = 697.9 PLP
    // 4. Pool's aum by max price should be:
    // DAI to removed from AUM is ((72 * 1096.7) / 797.6) = 99 DAI
    // MATIC to removed from AUM is ((27.7 * 997.7) / 725.6) / 500 = 0.076175 MATIC
    // 0.7 + ((1 * (1-0.003) - 0.076175) * 500) + (0.01 * (1-0.003) * 60000) ~= 1059.8376822125 USD
    // 5. Pool's aum by min price should be:
    // 0.7 + ((1 * (1-0.003) - 0.076175) * 400) + (0.01 * (1-0.003) * 60000) ~= 967.23 USD
    assertEq(matic.balanceOf(ALICE), 75946475000000000);
    assertEq(poolGetterFacet.plp().balanceOf(ALICE), 0 ether);
    assertEq(poolGetterFacet.plp().totalSupply(), 697.9 ether);
    assertEq(poolGetterFacet.getAumE18(true), 1059.3125 ether);
    assertEq(poolGetterFacet.getAumE18(false), 967.23 ether);

    vm.stopPrank();
    // ------- Finish Alice session -------

    // ------- Bob session -------
    vm.startPrank(BOB);

    // Bob remove 299.1 PLP to MATIC
    poolGetterFacet.plp().approve(address(poolRouter), 299.1 ether);
    plpStaking.withdraw(address(poolGetterFacet.plp()), 299.1 ether);
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(matic),
      299.1 ether,
      BOB,
      0
    );

    // Bob remove 299.1 PLP, the following criteria needs to statisfy:
    // 1. Bob should get ((299.1 * 967.23) / 697.9) * (1-0.003) / 500 ~= 0.826567122857143 MATIC
    // 2. Bob should have 299.1 - 299.1 = 0 PLP
    // 3. PLP's total supply should be 697.9 - 299.1 = 398.8 PLP
    // 4. Pool's aum by max price should be:
    // MATIC to removed from AUM is ((299.1 * 967.23) / 697.9) / 500 ~= 0.8290542857142859 MATIC
    // 0.7 + ((1 * (1-0.003) - 0.076175 - 0.8290542857142859) * 500) + (0.01 * (1-0.003) * 60000) ~= 644.785357142857 USD
    // 5. Pool's aum by min price should be:
    // 0.7 + ((1 * (1-0.003) - 0.076175 - 0.8290542857142859) * 400) + (0.01 * (1-0.003) * 60000) ~= 635.6082857142856 USD
    // 6. Pool should have 0.7 DAI left in liquidity.
    // 7. Pool should have 0.0997 WBTC left in liquidity.
    // 8. Pool should have 0.09177071428571415 MATIC left in liquidity.
    assertEq(matic.balanceOf(BOB), 826567122857142856);
    assertEq(poolGetterFacet.plp().balanceOf(BOB), 0 ether);
    assertEq(poolGetterFacet.plp().totalSupply(), 398.8 ether);
    assertEq(poolGetterFacet.getAumE18(true), 644785357142857143000);
    assertEq(poolGetterFacet.getAumE18(false), 635608285714285714400);
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 0.7 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 997000);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 91770714285714286);

    vm.stopPrank();
    // ------- Finish Bob session -------

    // ------- Cat session -------
    vm.startPrank(CAT);

    // Cat remove 375 PLP to WBTC
    poolGetterFacet.plp().approve(address(poolRouter), 375 ether);
    plpStaking.withdraw(address(poolGetterFacet.plp()), 375 ether);
    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(wbtc),
      375 ether,
      CAT,
      0
    );

    // Cat removed 375 PLP, the following criteria needs to statisfy:
    // 1. Cat should get ((375 * 635.6082857142857) / 398.8) * (1-0.003) / 60000 ~= 0.009931379464285715 WBTC
    // 2. Cat should have 398.8 - 375 = 23.8 PLP
    // 3. PLP's total supply should be 398.8 - 375 = 23.8 PLP
    // 4. Pool's aum by max price should be:
    // WBTC to removed from AUM is ((375 * 635.6082857142857) / 398.8) / 60000 ~= 0.009961263254047857 WBTC
    // 0.7 + (0.09177071428571415 * 500) + ((0.00997 - 0.00996126) * 60000) ~= 47.109757142857084 USD
    // 5. Pool's aum by min price should be:
    // 0.7 + (0.09177071428571415 * 400) + ((0.00997 - 0.00996126) * 60000) ~= 37.93268571428567 USD
    // 6. Pool should have 0.7 DAI left in liquidity.
    // 7. Pool should have 0.00000874 WBTC left in liquidity.
    // 8. Pool should have 0.09177071428571415 MATIC left in liquidity.
    assertEq(wbtc.balanceOf(CAT), 993137);
    assertEq(poolGetterFacet.plp().balanceOf(address(plpStaking)), 23.8 ether);
    assertEq(poolGetterFacet.plp().totalSupply(), 23.8 ether);
    assertEq(poolGetterFacet.getAumE18(true), 47109757142857143000);
    assertEq(poolGetterFacet.getAumE18(false), 37932685714285714400);
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 0.7 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 874);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 91770714285714286);
  }

  function testRevert_Slippage() external {
    // Mint 100 DAI to Alice
    dai.mint(ALICE, 100 ether);

    // ------- Alice session -------
    // Alice as a liquidity provider for DAI
    vm.startPrank(ALICE);

    // Perform add liquidity
    dai.approve(address(poolRouter), 100 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(dai),
      100 ether,
      ALICE,
      0
    );

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

    // Perform add liquidity
    matic.approve(address(poolRouter), 1 ether);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(matic),
      1 ether,
      BOB,
      0
    );

    vm.stopPrank();
    // ------- Finish Bob session -------

    maticPriceFeed.setLatestAnswer(400 * 10**8);
    maticPriceFeed.setLatestAnswer(500 * 10**8);
    maticPriceFeed.setLatestAnswer(400 * 10**8);

    assertEq(poolGetterFacet.getAumE18(true), 598.2 ether);
    assertEq(poolGetterFacet.getAumE18(false), 498.5 ether);

    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);

    // Mint 0.01 WBTC (600 USD) to CAT.
    wbtc.mint(CAT, 1000000);
    vm.warp(block.timestamp + 1 days);

    // ------- Cat session -------
    vm.startPrank(CAT);
    wbtc.approve(address(poolRouter), type(uint256).max);

    // Perform add liquidity
    wbtc.approve(address(poolRouter), 1000000);
    plp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity(
      address(poolDiamond),
      address(wbtc),
      1000000,
      CAT,
      0
    );

    vm.stopPrank();
    // ------- Finish Cat session -------

    assertEq(poolGetterFacet.totalUsdDebt(), 997 ether);

    // Warp so that the cool down is passed.
    vm.warp(block.timestamp + 1 days + 1);

    // ------- Alice session -------
    vm.startPrank(ALICE);

    // Perform remove liquidity
    // Alice remove 72 PLP, the following criteria needs to statisfy:
    // 1. Alice should get ((72 * 1096.7) / 797.6) * (1-0.003) / 1 ~= 98.703 DAI
    // 2. Alice should have 99.7 - 72 = 27.7 PLP
    poolGetterFacet.plp().approve(address(poolRouter), 72 ether);
    plpStaking.withdraw(address(poolGetterFacet.plp()), 72 ether);
    vm.expectRevert(
      abi.encodeWithSelector(
        PoolRouter.PoolRouter_InsufficientOutputAmount.selector,
        100 ether,
        98.703 ether
      )
    );

    poolRouter.removeLiquidity(
      address(poolDiamond),
      address(dai),
      72 ether,
      ALICE,
      100 ether
    );
    vm.stopPrank();
  }
}
