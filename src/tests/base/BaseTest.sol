// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { DSTest } from "./DSTest.sol";

import { VM } from "../utils/VM.sol";
import { console } from "../utils/console.sol";
import { stdError } from "../utils/stdError.sol";

import { Constants as CoreConstants } from "../../core/Constants.sol";

import { MockErc20 } from "../mocks/MockErc20.sol";
import { MockChainlinkPriceFeed } from "../mocks/MockChainlinkPriceFeed.sol";

import { PoolOracle } from "../../core/PoolOracle.sol";
import { PoolConfig } from "../../core/PoolConfig.sol";
import { PoolMath } from "../../core/PoolMath.sol";
import { PLP } from "../../tokens/PLP.sol";
import { Pool } from "../../core/Pool.sol";
import { PoolRouter } from "src/core/pool-diamond/PoolRouter.sol";

// Diamond things
// Facets
import { DiamondCutFacet, DiamondCutInterface } from "../../core/pool-diamond/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../../core/pool-diamond/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet, OwnershipFacetInterface } from "../../core/pool-diamond/facets/OwnershipFacet.sol";
import { GetterFacet, GetterFacetInterface } from "../../core/pool-diamond/facets/GetterFacet.sol";
import { FundingRateFacet, FundingRateFacetInterface } from "../../core/pool-diamond/facets/FundingRateFacet.sol";
import { LiquidityFacet, LiquidityFacetInterface } from "../../core/pool-diamond/facets/LiquidityFacet.sol";
import { PerpTradeFacet, PerpTradeFacetInterface } from "../../core/pool-diamond/facets/PerpTradeFacet.sol";
import { DiamondInitializer } from "../../core/pool-diamond/initializers/DiamondInitializer.sol";
import { PoolDiamond } from "../../core/pool-diamond/PoolDiamond.sol";

// solhint-disable const-name-snakecase
// solhint-disable no-inline-assembly
contract BaseTest is DSTest, CoreConstants {
  struct PoolConfigConstructorParams {
    address treasury;
    uint64 fundingInterval;
    uint64 mintBurnFeeBps;
    uint64 taxBps;
    uint64 stableFundingRateFactor;
    uint64 fundingRateFactor;
    uint64 liquidityCoolDownPeriod;
    uint256 liquidationFeeUsd;
  }

  VM internal constant vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  address internal constant ALICE = address(1);
  address internal constant BOB = address(2);
  address internal constant CAT = address(3);
  address internal constant DAVE = address(4);

  address internal constant TREASURY = address(168168168168);

  MockErc20 internal matic;
  MockErc20 internal weth;
  MockErc20 internal wbtc;
  MockErc20 internal dai;
  MockErc20 internal usdc;
  MockErc20 internal randomErc20;

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
    randomErc20 = deployMockErc20("Random ERC20", "RAND", 18);

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

  function buildDefaultSetTokenConfigInput()
    internal
    view
    returns (address[] memory, PoolConfig.TokenConfig[] memory)
  {
    address[] memory tokens = new address[](3);
    tokens[0] = address(dai);
    tokens[1] = address(wbtc);
    tokens[2] = address(matic);

    PoolConfig.TokenConfig[] memory tokenConfigs = new PoolConfig.TokenConfig[](
      3
    );
    tokenConfigs[0] = PoolConfig.TokenConfig({
      accept: true,
      isStable: true,
      isShortable: false,
      decimals: dai.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0
    });
    tokenConfigs[1] = PoolConfig.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: wbtc.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0
    });
    tokenConfigs[2] = PoolConfig.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: matic.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0
    });

    return (tokens, tokenConfigs);
  }

  function buildFacetCut(
    address facet,
    DiamondCutInterface.FacetCutAction cutAction,
    bytes4[] memory selectors
  ) internal pure returns (DiamondCutInterface.FacetCut[] memory) {
    DiamondCutInterface.FacetCut[]
      memory facetCuts = new DiamondCutInterface.FacetCut[](1);
    facetCuts[0] = DiamondCutInterface.FacetCut({
      action: cutAction,
      facetAddress: facet,
      functionSelectors: selectors
    });

    return facetCuts;
  }

  function deployDiamondCutFacet() internal returns (DiamondCutFacet) {
    return new DiamondCutFacet();
  }

  function deployDiamondInitializer() internal returns (DiamondInitializer) {
    return new DiamondInitializer();
  }

  function deployDiamondLoupeFacet(DiamondCutFacet diamondCutFacet)
    internal
    returns (DiamondLoupeFacet, bytes4[] memory functionSelectors)
  {
    DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();

    bytes4[] memory selectors = new bytes4[](4);
    selectors[0] = DiamondLoupeFacet.facets.selector;
    selectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
    selectors[2] = DiamondLoupeFacet.facetAddresses.selector;
    selectors[3] = DiamondLoupeFacet.facetAddress.selector;

    DiamondCutInterface.FacetCut[] memory facetCuts = buildFacetCut(
      address(diamondLoupeFacet),
      DiamondCutInterface.FacetCutAction.Add,
      selectors
    );

    diamondCutFacet.diamondCut(facetCuts, address(0), "");
    return (diamondLoupeFacet, selectors);
  }

  function deployOwnershipFacet(DiamondCutFacet diamondCutFacet)
    internal
    returns (OwnershipFacet, bytes4[] memory functionSelectors)
  {
    OwnershipFacet ownershipFacet = new OwnershipFacet();

    bytes4[] memory selectors = new bytes4[](2);
    selectors[0] = OwnershipFacet.transferOwnership.selector;
    selectors[1] = OwnershipFacet.owner.selector;

    DiamondCutInterface.FacetCut[] memory facetCuts = buildFacetCut(
      address(ownershipFacet),
      DiamondCutInterface.FacetCutAction.Add,
      selectors
    );

    diamondCutFacet.diamondCut(facetCuts, address(0), "");
    return (ownershipFacet, selectors);
  }

  function deployGetterFacet(DiamondCutFacet diamondCutFacet)
    internal
    returns (GetterFacet, bytes4[] memory functionSelectors)
  {
    GetterFacet getterFacet = new GetterFacet();

    bytes4[] memory selectors = new bytes4[](30);
    selectors[0] = GetterFacet.getAddLiquidityFeeBps.selector;
    selectors[1] = GetterFacet.getRemoveLiquidityFeeBps.selector;
    selectors[2] = GetterFacet.getSwapFeeBps.selector;
    selectors[3] = GetterFacet.getAum.selector;
    selectors[4] = GetterFacet.getAumE18.selector;
    selectors[5] = GetterFacet.getNextFundingRate.selector;
    selectors[6] = GetterFacet.plp.selector;
    selectors[7] = GetterFacet.lastAddLiquidityAtOf.selector;
    selectors[8] = GetterFacet.totalUsdDebt.selector;
    selectors[9] = GetterFacet.liquidityOf.selector;
    selectors[10] = GetterFacet.feeReserveOf.selector;
    selectors[11] = GetterFacet.usdDebtOf.selector;
    selectors[12] = GetterFacet.getDelta.selector;
    selectors[13] = GetterFacet.getEntryFundingRate.selector;
    selectors[14] = GetterFacet.getFundingFee.selector;
    selectors[15] = GetterFacet.getNextShortAveragePrice.selector;
    selectors[16] = GetterFacet.getPositionFee.selector;
    selectors[17] = GetterFacet.getPositionNextAveragePrice.selector;
    selectors[18] = GetterFacet.getSubAccount.selector;
    selectors[19] = GetterFacet.guaranteedUsdOf.selector;
    selectors[20] = GetterFacet.reservedOf.selector;
    selectors[21] = GetterFacet.getPosition.selector;
    selectors[22] = GetterFacet.getPositionWithSubAccountId.selector;
    selectors[23] = GetterFacet.getPositionDelta.selector;
    selectors[24] = GetterFacet.getPositionLeverage.selector;
    selectors[25] = GetterFacet.getRedemptionCollateral.selector;
    selectors[26] = GetterFacet.getRedemptionCollateralUsd.selector;
    selectors[27] = GetterFacet.shortSizeOf.selector;
    selectors[28] = GetterFacet.getPoolShortDelta.selector;
    selectors[29] = GetterFacet.shortAveragePriceOf.selector;

    DiamondCutInterface.FacetCut[] memory facetCuts = buildFacetCut(
      address(getterFacet),
      DiamondCutInterface.FacetCutAction.Add,
      selectors
    );

    diamondCutFacet.diamondCut(facetCuts, address(0), "");
    return (getterFacet, selectors);
  }

  function deployFundingRateFacet(DiamondCutFacet diamondCutFacet)
    internal
    returns (FundingRateFacet, bytes4[] memory functionSelectors)
  {
    FundingRateFacet fundingRateFacet = new FundingRateFacet();

    bytes4[] memory selectors = new bytes4[](1);
    selectors[0] = FundingRateFacet.updateFundingRate.selector;

    DiamondCutInterface.FacetCut[] memory facetCuts = buildFacetCut(
      address(fundingRateFacet),
      DiamondCutInterface.FacetCutAction.Add,
      selectors
    );

    diamondCutFacet.diamondCut(facetCuts, address(0), "");
    return (fundingRateFacet, selectors);
  }

  function deployLiquidityFacet(DiamondCutFacet diamondCutFacet)
    internal
    returns (LiquidityFacet, bytes4[] memory functionSelectors)
  {
    LiquidityFacet liquidityFacet = new LiquidityFacet();

    bytes4[] memory selectors = new bytes4[](3);
    selectors[0] = LiquidityFacet.addLiquidity.selector;
    selectors[1] = LiquidityFacet.removeLiquidity.selector;
    selectors[2] = LiquidityFacet.swap.selector;

    DiamondCutInterface.FacetCut[] memory facetCuts = buildFacetCut(
      address(liquidityFacet),
      DiamondCutInterface.FacetCutAction.Add,
      selectors
    );

    diamondCutFacet.diamondCut(facetCuts, address(0), "");
    return (liquidityFacet, selectors);
  }

  function deployPerpTradeFacet(DiamondCutFacet diamondCutFacet)
    internal
    returns (PerpTradeFacet, bytes4[] memory functionSelectors)
  {
    PerpTradeFacet perpTradeFacet = new PerpTradeFacet();

    bytes4[] memory selectors = new bytes4[](4);
    selectors[0] = PerpTradeFacet.checkLiquidation.selector;
    selectors[1] = PerpTradeFacet.increasePosition.selector;
    selectors[2] = PerpTradeFacet.decreasePosition.selector;
    selectors[3] = PerpTradeFacet.liquidate.selector;

    DiamondCutInterface.FacetCut[] memory facetCuts = buildFacetCut(
      address(perpTradeFacet),
      DiamondCutInterface.FacetCutAction.Add,
      selectors
    );

    diamondCutFacet.diamondCut(facetCuts, address(0), "");
    return (perpTradeFacet, selectors);
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

  function deployPoolOracle(uint80 roundDepth) internal returns (PoolOracle) {
    return new PoolOracle(roundDepth);
  }

  function deployPoolConfig(PoolConfigConstructorParams memory params)
    internal
    returns (PoolConfig)
  {
    return
      new PoolConfig(
        params.treasury,
        params.fundingInterval,
        params.mintBurnFeeBps,
        params.taxBps,
        params.stableFundingRateFactor,
        params.fundingRateFactor,
        params.liquidityCoolDownPeriod,
        params.liquidationFeeUsd
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

  function deployPoolDiamond(
    PoolConfigConstructorParams memory poolConfigConstructorParams
  )
    internal
    returns (
      PoolOracle,
      PoolConfig,
      address
    )
  {
    PoolOracle poolOracle = deployPoolOracle(3);
    PoolConfig poolConfig = deployPoolConfig(poolConfigConstructorParams);
    PLP plp = deployPLP();

    // Deploy DimondCutFacet
    DiamondCutFacet diamondCutFacet = deployDiamondCutFacet();

    // Deploy Pool Diamond
    PoolDiamond poolDiamond = new PoolDiamond(
      address(diamondCutFacet),
      plp,
      poolConfig,
      poolOracle
    );

    // Config
    plp.setMinter(address(poolDiamond), true);

    deployDiamondLoupeFacet(DiamondCutFacet(address(poolDiamond)));
    deployFundingRateFacet(DiamondCutFacet(address(poolDiamond)));
    deployGetterFacet(DiamondCutFacet(address(poolDiamond)));
    deployLiquidityFacet(DiamondCutFacet(address(poolDiamond)));
    deployOwnershipFacet(DiamondCutFacet(address(poolDiamond)));
    deployPerpTradeFacet(DiamondCutFacet(address(poolDiamond)));

    initializeDiamond(DiamondCutFacet(address(poolDiamond)));

    return (poolOracle, poolConfig, address(poolDiamond));
  }

  function initializeDiamond(DiamondCutFacet diamondCutFacet) internal {
    // Deploy DiamondInitializer
    DiamondInitializer diamondInitializer = deployDiamondInitializer();
    DiamondCutInterface.FacetCut[]
      memory facetCuts = new DiamondCutInterface.FacetCut[](0);
    diamondCutFacet.diamondCut(
      facetCuts,
      address(diamondInitializer),
      abi.encodeWithSelector(bytes4(keccak256("initialize()")))
    );
  }

  function deployPoolRouter(address wNative) internal returns (PoolRouter) {
    return new PoolRouter(wNative);
  }
}
