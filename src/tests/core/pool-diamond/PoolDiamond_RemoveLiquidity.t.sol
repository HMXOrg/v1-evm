// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolDiamond_BaseTest, PoolConfig, LibPoolConfigV1, Pool, console, GetterFacetInterface, LiquidityFacetInterface } from "./PoolDiamond_BaseTest.t.sol";

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
    vm.expectRevert(abi.encodeWithSignature("LibPoolV1_Forbidden()"));
    poolLiquidityFacet.removeLiquidity(ALICE, address(dai), address(this));
  }

  function testRevert_WhenAmountOutZero() external {
    dai.mint(address(this), 100 ether);

    dai.transfer(address(poolDiamond), 100 ether);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    vm.expectRevert(abi.encodeWithSignature("LiquidityFacet_BadAmount()"));
    poolLiquidityFacet.removeLiquidity(
      address(this),
      address(dai),
      address(this)
    );
  }

  function testRevert_WhenCoolDownNotPassed() external {
    dai.mint(address(this), 100 ether);

    dai.transfer(address(poolDiamond), 100 ether);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    poolGetterFacet.plp().transfer(address(poolDiamond), 1);

    vm.expectRevert(abi.encodeWithSignature("LiquidityFacet_CoolDown()"));
    poolLiquidityFacet.removeLiquidity(
      address(this),
      address(dai),
      address(this)
    );
  }

  function testCorrectness_WhenDynamicFeeOff() external {
    // Mint 100 DAI to Alice
    dai.mint(ALICE, 100 ether);

    // ------- Alice session -------
    // Alice as a liquidity provider for DAI
    vm.startPrank(ALICE);

    // Perform add liquidity
    dai.transfer(address(poolDiamond), 100 ether);
    poolLiquidityFacet.addLiquidity(ALICE, address(dai), ALICE);

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
    matic.transfer(address(poolDiamond), 1 ether);
    poolLiquidityFacet.addLiquidity(BOB, address(matic), BOB);

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
    wbtc.approve(address(poolDiamond), type(uint256).max);

    // Perform add liquidity
    wbtc.transfer(address(poolDiamond), 1000000);
    poolLiquidityFacet.addLiquidity(CAT, address(wbtc), CAT);

    vm.stopPrank();
    // ------- Finish Cat session -------

    assertEq(poolGetterFacet.totalUsdDebt(), 997 ether);

    // Warp so that the cool down is passed.
    vm.warp(block.timestamp + 1 days + 1);

    // ------- Alice session -------
    vm.startPrank(ALICE);

    // Perform remove liquidity
    poolGetterFacet.plp().transfer(address(poolDiamond), 72 ether);
    poolLiquidityFacet.removeLiquidity(ALICE, address(dai), ALICE);

    // Alice remove 72 PLP, the following criteria needs to statisfy:
    // 1. Alice should get ((72 * 1096.7) / 797.6) * (1-0.003) / 1 ~= 98.703 DAI
    // 2. Alice should have 99.7 - 72 = 27.7 PLP
    assertEq(dai.balanceOf(ALICE), 98703000000000000000);
    assertEq(poolGetterFacet.plp().balanceOf(ALICE), 27.7 ether);

    // Alice remove 27.7 PLP to MATIC
    poolGetterFacet.plp().transfer(address(poolDiamond), 27.7 ether);
    poolLiquidityFacet.removeLiquidity(ALICE, address(matic), ALICE);

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
    poolGetterFacet.plp().transfer(address(poolDiamond), 299.1 ether);
    poolLiquidityFacet.removeLiquidity(BOB, address(matic), BOB);

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
    poolGetterFacet.plp().transfer(address(poolDiamond), 375 ether);
    poolLiquidityFacet.removeLiquidity(CAT, address(wbtc), CAT);

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
    assertEq(poolGetterFacet.plp().balanceOf(CAT), 23.8 ether);
    assertEq(poolGetterFacet.plp().totalSupply(), 23.8 ether);
    assertEq(poolGetterFacet.getAumE18(true), 47109757142857143000);
    assertEq(poolGetterFacet.getAumE18(false), 37932685714285714400);
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 0.7 ether);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 874);
    assertEq(poolGetterFacet.liquidityOf(address(matic)), 91770714285714286);
  }
}
