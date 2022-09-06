// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { BaseTest, console, stdError, PoolConfig, PoolMath, PoolOracle, Pool, PoolRouter, OwnershipFacetInterface, GetterFacetInterface, LiquidityFacetInterface, PerpTradeFacetInterface } from "../../base/BaseTest.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract PoolDiamond_BaseTest is BaseTest {
  PoolConfig internal poolConfig;
  PoolOracle internal poolOracle;
  address internal poolDiamond;
  PoolRouter internal poolRouter;

  GetterFacetInterface internal poolGetterFacet;
  LiquidityFacetInterface internal poolLiquidityFacet;
  PerpTradeFacetInterface internal poolPerpTradeFacet;

  function setUp() public virtual {
    BaseTest.PoolConfigConstructorParams memory poolConfigParams = BaseTest
      .PoolConfigConstructorParams({
        treasury: TREASURY,
        fundingInterval: 8 hours,
        mintBurnFeeBps: 30,
        taxBps: 50,
        stableFundingRateFactor: 600,
        fundingRateFactor: 600,
        liquidityCoolDownPeriod: 1 days,
        liquidationFeeUsd: 5 * 10**30
      });

    (poolOracle, poolConfig, poolDiamond) = deployPoolDiamond(poolConfigParams);

    (
      address[] memory tokens,
      PoolOracle.PriceFeedInfo[] memory priceFeedInfo
    ) = buildDefaultSetPriceFeedInput();
    poolOracle.setPriceFeed(tokens, priceFeedInfo);

    poolGetterFacet = GetterFacetInterface(poolDiamond);
    poolLiquidityFacet = LiquidityFacetInterface(poolDiamond);
    poolPerpTradeFacet = PerpTradeFacetInterface(poolDiamond);

    poolRouter = deployPoolRouter(address(matic));
    poolConfig.setRouter(address(poolRouter));
  }

  function checkPoolBalanceWithState(address token, uint256 offset) internal {
    uint256 balance = IERC20(token).balanceOf(address(poolDiamond));
    assertEq(
      balance,
      poolGetterFacet.liquidityOf(token) +
        poolGetterFacet.feeReserveOf(token) +
        offset
    );
  }
}
