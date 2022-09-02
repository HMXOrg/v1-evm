// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { DSTest } from "./DSTest.sol";

import { VM } from "../utils/VM.sol";
import { console } from "../utils/console.sol";
import { math } from "../utils/math.sol";

import { Constants as CoreConstants } from "../../core/Constants.sol";

import { MockErc20 } from "../mocks/MockERC20.sol";
import { MockWNative } from "../mocks/MockWNative.sol";
import { MockChainlinkPriceFeed } from "../mocks/MockChainlinkPriceFeed.sol";

import { PoolOracle } from "../../core/PoolOracle.sol";
import { PoolConfig } from "../../core/PoolConfig.sol";
import { PoolMath } from "../../core/PoolMath.sol";
import { PLP } from "../../tokens/PLP.sol";
import { P88 } from "../../tokens/P88.sol";
import { EsP88 } from "../../tokens/EsP88.sol";
import { DragonPoint } from "../../tokens/DragonPoint.sol";
import { Pool } from "../../core/Pool.sol";
import { PLPStaking } from "../../staking/PLPStaking.sol";
import { DragonStaking } from "../../staking/DragonStaking.sol";
import { FeedableRewarder } from "../../staking/FeedableRewarder.sol";
import { AdHocMintRewarder } from "../../staking/AdHocMintRewarder.sol";
import { WFeedableRewarder } from "../../staking/WFeedableRewarder.sol";
import { Compounder } from "../../staking/Compounder.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { LockdropCompounder } from "../../lockdrop/LockdropCompounder.sol";
import { LockdropConfig } from "../../lockdrop/LockdropConfig.sol";
import { IPool } from "../../interfaces/IPool.sol";
import { IStaking } from "../../staking/interfaces/IStaking.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LockdropGateway } from "../../lockdrop/LockdropGateway.sol";

// solhint-disable const-name-snakecase
// solhint-disable no-inline-assembly
contract BaseTest is DSTest, CoreConstants {
  struct PoolConfigConstructorParams {
    uint64 fundingInterval;
    uint64 mintBurnFeeBps;
    uint64 taxBps;
    uint64 stableFundingRateFactor;
    uint64 fundingRateFactor;
    uint64 liquidityCoolDownPeriod;
  }

  VM internal constant vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  // Note: Avoid using address(1) as it is reserved for Ecrecover.
  // ref: https://ethereum.stackexchange.com/questions/89447/how-does-ecrecover-get-compiled
  // One pitfall is that, when transferring native token to address(1),
  // it will revert with PRECOMPILE::ecrecover.
  address internal constant ALICE = address(5);
  address internal constant BOB = address(2);
  address internal constant CAT = address(3);
  address internal constant DAVE = address(4);

  MockErc20 internal matic;
  MockErc20 internal weth;
  MockErc20 internal wbtc;
  MockErc20 internal dai;
  MockErc20 internal usdc;

  MockChainlinkPriceFeed internal maticPriceFeed;
  MockChainlinkPriceFeed internal wethPriceFeed;
  MockChainlinkPriceFeed internal wbtcPriceFeed;
  MockChainlinkPriceFeed internal daiPriceFeed;
  MockChainlinkPriceFeed internal usdcPriceFeed;

  constructor() {
    matic = deployMockErc20("Matic Token", "MATIC", 18);
    weth = deployMockErc20("Wrapped Ethereum", "WETH", 18);
    wbtc = deployMockErc20("Wrapped Bitcoin", "WBTC", 8);
    dai = deployMockErc20("DAI Stablecoin", "DAI", 18);
    usdc = deployMockErc20("USD Coin", "USDC", 6);

    maticPriceFeed = deployMockChainlinkPriceFeed();
    wethPriceFeed = deployMockChainlinkPriceFeed();
    wbtcPriceFeed = deployMockChainlinkPriceFeed();
    daiPriceFeed = deployMockChainlinkPriceFeed();
    usdcPriceFeed = deployMockChainlinkPriceFeed();
  }

  function buildDefaultSetPriceFeedInput()
    internal
    view
    returns (address[] memory, PoolOracle.PriceFeedInfo[] memory)
  {
    address[] memory tokens = new address[](5);
    tokens[0] = address(matic);
    tokens[1] = address(weth);
    tokens[2] = address(wbtc);
    tokens[3] = address(dai);
    tokens[4] = address(usdc);

    PoolOracle.PriceFeedInfo[]
      memory priceFeedInfo = new PoolOracle.PriceFeedInfo[](5);
    priceFeedInfo[0] = PoolOracle.PriceFeedInfo({
      priceFeed: maticPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: false
    });
    priceFeedInfo[1] = PoolOracle.PriceFeedInfo({
      priceFeed: wethPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: false
    });
    priceFeedInfo[2] = PoolOracle.PriceFeedInfo({
      priceFeed: wbtcPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: false
    });
    priceFeedInfo[3] = PoolOracle.PriceFeedInfo({
      priceFeed: daiPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: false
    });
    priceFeedInfo[4] = PoolOracle.PriceFeedInfo({
      priceFeed: usdcPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: true
    });

    return (tokens, priceFeedInfo);
  }

  function deployMockWNative() internal returns (MockWNative) {
    return new MockWNative();
  }

  function deployMockErc20(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal returns (MockErc20) {
    return new MockErc20(name, symbol, decimals);
  }

  function deployMockChainlinkPriceFeed()
    internal
    returns (MockChainlinkPriceFeed)
  {
    return new MockChainlinkPriceFeed();
  }

  function deployPLP() internal returns (PLP) {
    return new PLP();
  }

  function deployP88() internal returns (P88) {
    return new P88();
  }

  function deployEsP88() internal returns (EsP88) {
    return new EsP88();
  }

  function deployDragonPoint() internal returns (DragonPoint) {
    return new DragonPoint();
  }

  function deployPoolOracle(uint80 roundDepth) internal returns (PoolOracle) {
    return new PoolOracle(roundDepth);
  }

  function deployPoolConfig(PoolConfigConstructorParams memory params)
    internal
    returns (PoolConfig)
  {
    return
      new PoolConfig(
        params.fundingInterval,
        params.mintBurnFeeBps,
        params.taxBps,
        params.stableFundingRateFactor,
        params.fundingRateFactor,
        params.liquidityCoolDownPeriod
      );
  }

  function deployPoolMath() internal returns (PoolMath) {
    return new PoolMath();
  }

  function deployFullPool(
    PoolConfigConstructorParams memory poolConfigConstructorParams
  )
    internal
    returns (
      PoolOracle,
      PoolConfig,
      PoolMath,
      Pool
    )
  {
    // Deploy Pool's dependencies
    PoolOracle poolOracle = deployPoolOracle(3);
    PoolConfig poolConfig = deployPoolConfig(poolConfigConstructorParams);
    PoolMath poolMath = deployPoolMath();
    PLP plp = deployPLP();

    // Deploy Pool
    Pool pool = new Pool(plp, poolConfig, poolMath, poolOracle);

    // Config
    plp.setMinter(address(pool), true);

    return (poolOracle, poolConfig, poolMath, pool);
  }

  function deployPLPStaking() internal returns (PLPStaking) {
    return new PLPStaking();
  }

  function deployDragonStaking(address dragonPointToken)
    internal
    returns (DragonStaking)
  {
    return new DragonStaking(dragonPointToken);
  }

  function deployFeedableRewarder(
    string memory name,
    address rewardToken,
    address staking
  ) internal returns (FeedableRewarder) {
    return new FeedableRewarder(name, rewardToken, staking);
  }

  function deployAdHocMintRewarder(
    string memory name,
    address rewardToken,
    address staking
  ) internal returns (AdHocMintRewarder) {
    return new AdHocMintRewarder(name, rewardToken, staking);
  }

  function deployWFeedableRewarder(
    string memory name,
    address rewardToken,
    address staking
  ) internal returns (WFeedableRewarder) {
    return new WFeedableRewarder(name, rewardToken, staking);
  }

  function deployCompounder(
    address dp,
    address compoundPool,
    address[] memory tokens,
    bool[] memory isCompoundTokens_
  ) internal returns (Compounder) {
    return new Compounder(dp, compoundPool, tokens, isCompoundTokens_);
  }

  function deployLockdrop(
    address lockdropToken,
    IPool pool,
    LockdropConfig lockdropConfig,
    address[] memory rewardTokens,
    address nativeTokenAddress
  ) internal returns (Lockdrop) {
    return
      new Lockdrop(
        lockdropToken,
        pool,
        lockdropConfig,
        rewardTokens,
        nativeTokenAddress
      );
  }

  function deployLockdropConfig(
    uint256 startLockTimestamp,
    IStaking plpStaking,
    IERC20 plpToken,
    IERC20 p88Token,
    address gatewayAddress,
    address lockdropCompounder
  ) internal returns (LockdropConfig) {
    return
      new LockdropConfig(
        startLockTimestamp,
        plpStaking,
        plpToken,
        p88Token,
        gatewayAddress,
        lockdropCompounder
      );
  }

  function deployLockdropGateway(IERC20 plpToken, IStaking plpStaking)
    internal
    returns (LockdropGateway)
  {
    return new LockdropGateway(plpToken, plpStaking);
  }

  function deployLockdropCompounder(address esp88Token, address dragonStaking)
    internal
    returns (LockdropCompounder)
  {
    return new LockdropCompounder(esp88Token, dragonStaking);
  }
}
