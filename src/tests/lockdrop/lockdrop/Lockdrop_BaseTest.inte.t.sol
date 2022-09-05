// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../base/DSTest.sol";
import { BaseTest, math, console, IPool, PoolConfig, PoolMath, PoolOracle, Pool, PLPStaking, DragonStaking, DragonPoint, PLP, P88, EsP88, MockErc20, MockWNative, FeedableRewarder, WFeedableRewarder, Lockdrop, LockdropConfig, LockdropGateway, LockdropCompounder } from "../../base/BaseTest.sol";

abstract contract Lockdrop_BaseTest is BaseTest {
  PLP internal plp;
  P88 internal p88;
  EsP88 internal esP88;
  DragonPoint internal dragonPoint;
  MockWNative internal revenueToken;

  PLPStaking internal plpStaking;
  DragonStaking internal dragonStaking;

  WFeedableRewarder internal revenueRewarder;
  FeedableRewarder internal esP88Rewarder;
  FeedableRewarder internal PLPRewarder;

  LockdropConfig internal lockdropConfig;
  Lockdrop internal lockdrop;
  LockdropGateway internal lockdropGateway;
  LockdropCompounder internal lockdropCompounder;

  PoolConfig internal poolConfig;
  PoolMath internal poolMath;
  PoolOracle internal poolOracle;
  Pool internal pool;

  address[] internal rewardsTokens;

  function setUp() public virtual {
    // Setup use token
    vm.startPrank(DAVE);
    plpStaking = BaseTest.deployPLPStaking();

    p88 = BaseTest.deployP88();
    p88.setMinter(DAVE, true);

    dragonPoint = BaseTest.deployDragonPoint();
    dragonPoint.setMinter(DAVE, true);

    esP88 = BaseTest.deployEsP88();
    esP88.setMinter(DAVE, true);

    revenueToken = deployMockWNative();

    rewardsTokens.push(address(esP88));
    rewardsTokens.push(address(revenueToken));

    //  Setup for Pool
    BaseTest.PoolConfigConstructorParams memory poolConfigParams = BaseTest
      .PoolConfigConstructorParams({
        treasury: address(1),
        fundingInterval: 8 hours,
        mintBurnFeeBps: 30,
        taxBps: 50,
        stableFundingRateFactor: 600,
        fundingRateFactor: 600,
        liquidityCoolDownPeriod: 1 days,
        liquidationFeeUsd: 0
      });

    (poolOracle, poolConfig, poolMath, pool) = deployFullPool(poolConfigParams);
    plp = PLP(address(pool.plp()));

    (
      address[] memory tokens,
      PoolOracle.PriceFeedInfo[] memory priceFeedInfo
    ) = buildDefaultSetPriceFeedInput();
    poolOracle.setPriceFeed(tokens, priceFeedInfo);

    address[] memory poolTokens = new address[](1);
    poolTokens[0] = address(usdc);

    PoolConfig.TokenConfig[]
      memory poolTokenConfigs = new PoolConfig.TokenConfig[](1);

    poolTokenConfigs[0] = PoolConfig.TokenConfig({
      accept: true,
      isStable: true,
      isShortable: false,
      decimals: usdc.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0
    });

    poolConfig.setTokenConfigs(poolTokens, poolTokenConfigs);

    //  setup for staking and rewarder
    revenueRewarder = BaseTest.deployWFeedableRewarder(
      "Protocol Revenue Rewarder",
      address(revenueToken),
      address(plpStaking)
    );
    esP88Rewarder = BaseTest.deployFeedableRewarder(
      "esP88 Rewarder",
      address(esP88),
      address(plpStaking)
    );

    address[] memory rewarders = new address[](2);
    rewarders[0] = address(revenueRewarder);
    rewarders[1] = address(esP88Rewarder);

    plpStaking.addStakingToken(address(plp), rewarders);

    dragonStaking = BaseTest.deployDragonStaking(address(dragonPoint));
    dragonPoint.setMinter(address(dragonStaking), true);
    dragonPoint.setTransferrer(address(dragonStaking), true);

    lockdropGateway = BaseTest.deployLockdropGateway(
      address(plp),
      address(plpStaking)
    );
    lockdropCompounder = BaseTest.deployLockdropCompounder(
      address(esP88),
      address(dragonStaking)
    );

    // startLockTimestamp = 1 day
    lockdropConfig = BaseTest.deployLockdropConfig(
      1 days,
      address(plpStaking),
      address(plp),
      address(p88),
      address(lockdropGateway),
      address(lockdropCompounder)
    );

    // Lock token is USDC
    lockdrop = BaseTest.deployLockdrop(
      address(usdc),
      address(pool),
      address(lockdropConfig),
      rewardsTokens,
      address(revenueToken)
    );

    vm.stopPrank();
  }
}