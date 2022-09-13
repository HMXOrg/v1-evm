// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { BaseTest, console, stdError, MockFlashLoanBorrower, PoolConfig, LibPoolConfigV1, PoolOracle, Pool, PoolRouter, OwnershipFacetInterface, GetterFacetInterface, LiquidityFacetInterface, PerpTradeFacetInterface, AdminFacetInterface } from "../../base/BaseTest.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract PoolDiamond_BaseTest is BaseTest {
  PoolOracle internal poolOracle;
  address internal poolDiamond;
  PoolRouter internal poolRouter;

  AdminFacetInterface internal poolAdminFacet;
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

    (poolOracle, poolDiamond) = deployPoolDiamond(poolConfigParams);

    (
      address[] memory tokens,
      PoolOracle.PriceFeedInfo[] memory priceFeedInfo
    ) = buildDefaultSetPriceFeedInput();
    poolOracle.setPriceFeed(tokens, priceFeedInfo);

    poolAdminFacet = AdminFacetInterface(poolDiamond);
    poolGetterFacet = GetterFacetInterface(poolDiamond);
    poolLiquidityFacet = LiquidityFacetInterface(poolDiamond);
    poolPerpTradeFacet = PerpTradeFacetInterface(poolDiamond);

    poolRouter = deployPoolRouter(address(matic));
    poolAdminFacet.setRouter(address(poolRouter));
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
