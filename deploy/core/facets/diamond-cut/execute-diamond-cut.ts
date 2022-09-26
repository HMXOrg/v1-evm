// import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { DeployFunction } from "hardhat-deploy/types";
// import { ethers } from "hardhat";
// import {
//   DiamondCutFacet__factory,
//   DiamondLoupeFacet__factory,
//   FundingRateFacet__factory,
//   GetterFacet__factory,
//   LiquidityFacetInterface__factory,
//   OwnershipFacet__factory,
//   PerpTradeFacet__factory,
// } from "../../../typechain";
// import { getConfig } from "../../utils/config";

// const config = getConfig();

// enum FacetCutAction {
//   Add,
//   Replace,
//   Remove,
// }

// const facetCuts = [
//   {
//     facetAddress: config.Pools.PLP.facets.liquidity,
//     action: FacetCutAction.Add,
//     functionSelectors: [
//       LiquidityFacetInterface__factory.createInterface().getSighash(
//         "addLiquidity(address,address,address)"
//       ),
//       LiquidityFacetInterface__factory.createInterface().getSighash(
//         "removeLiquidity(address,address,address)"
//       ),
//     ],
//   },
//   {
//     facetAddress: config.Pools.PLP.facets.diamondLoupe,
//     action: FacetCutAction.Add,
//     functionSelectors: [
//       DiamondLoupeFacet__factory.createInterface().getSighash("facets()"),
//       DiamondLoupeFacet__factory.createInterface().getSighash(
//         "facetFunctionSelectors(address)"
//       ),
//       DiamondLoupeFacet__factory.createInterface().getSighash(
//         "facetAddresses()"
//       ),
//       DiamondLoupeFacet__factory.createInterface().getSighash(
//         "facetAddress(bytes4)"
//       ),
//       DiamondLoupeFacet__factory.createInterface().getSighash(
//         "supportsInterface(bytes4)"
//       ),
//     ],
//   },
//   {
//     facetAddress: config.Pools.PLP.facets.fundingRate,
//     action: FacetCutAction.Add,
//     functionSelectors: [
//       FundingRateFacet__factory.createInterface().getSighash(
//         "updateFundingRate(address, address)"
//       ),
//     ],
//   },
//   {
//     facetAddress: config.Pools.PLP.facets.getter,
//     action: FacetCutAction.Add,
//     functionSelectors: [
//       GetterFacet__factory.createInterface().getSighash("additionalAum()"),
//       GetterFacet__factory.createInterface().getSighash("config()"),
//       GetterFacet__factory.createInterface().getSighash("discountedAum()"),
//       GetterFacet__factory.createInterface().getSighash(
//         "feeReserveOf(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "guaranteedUsdOf(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "lastAddLiquidityAtOf(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "lastFundingTimeOf(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash("liquidityOf(address)"),
//       GetterFacet__factory.createInterface().getSighash("oracle()"),
//       GetterFacet__factory.createInterface().getSighash("plp()"),
//       GetterFacet__factory.createInterface().getSighash("reservedOf(address)"),
//       GetterFacet__factory.createInterface().getSighash("shortSizeOf(address)"),
//       GetterFacet__factory.createInterface().getSighash(
//         "shortAveragePriceOf(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "sumBorrowingRateOf(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash("totalOf(address)"),
//       GetterFacet__factory.createInterface().getSighash("totalUsdDebt()"),
//       GetterFacet__factory.createInterface().getSighash("usdDebtOf(address)"),

//       GetterFacet__factory.createInterface().getSighash(
//         "getDelta(address,uint256,uint256,bool,uint256)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getEntryBorrowingRate(address,address,bool)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getBorrowingFee(address,address,address,bool,uint256,uint256)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getNextShortAveragePrice(address,uint256,uint256)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getPoolShortDelta(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getPositionWithSubAccountId(address,uint256,address,address,bool)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getPosition(address,address,address,bool)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getPositionDelta(address,uint256,address,address,bool)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getPositionFee(address,address,address,bool,uint256)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getPositionLeverage(address,uint256,address,address,bool)"
//       ),

//       GetterFacet__factory.createInterface().getSighash(
//         "getPositionNextAveragePrice(address,uint256,uint256,bool,uint256,uint256,uint256)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getRedemptionCollateral(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getRedemptionCollateralUsd(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getSubAccount(address,uint256)"
//       ),

//       GetterFacet__factory.createInterface().getSighash(
//         "getSwapFeeBps(address,address,uint256)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getTargetValue(address)"
//       ),
//       GetterFacet__factory.createInterface().getSighash("getAum(bool)"),
//       GetterFacet__factory.createInterface().getSighash("getAumE18(bool)"),
//       GetterFacet__factory.createInterface().getSighash(
//         "getAddLiquidityFeeBps(address,uint256)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getRemoveLiquidityFeeBps(address,uint256)"
//       ),
//       GetterFacet__factory.createInterface().getSighash(
//         "getNextBorrowingRate(address)"
//       ),
//     ],
//   },
//   {
//     facetAddress: config.Pools.PLP.facets.ownership,
//     action: FacetCutAction.Add,
//     functionSelectors: [
//       OwnershipFacet__factory.createInterface().getSighash("owner()"),
//     ],
//   },
//   {
//     facetAddress: config.Pools.PLP.facets.perpTrade,
//     action: FacetCutAction.Add,
//     functionSelectors: [
//       PerpTradeFacet__factory.createInterface().getSighash(
//         "checkLiquidation(address,address,address,bool,bool)"
//       ),
//       PerpTradeFacet__factory.createInterface().getSighash(
//         "decreasePosition(address,uint256,address,address,uint256,uint256,bool,address)"
//       ),
//       PerpTradeFacet__factory.createInterface().getSighash(
//         "increasePosition(address,uint256,address,address,uint256,bool)"
//       ),
//       PerpTradeFacet__factory.createInterface().getSighash(
//         "liquidate(address,uint256,address,address,bool,address)"
//       ),
//     ],
//   },
// ];

// const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
//   const deployer = (await ethers.getSigners())[0];

//   const poolDiamond = DiamondCutFacet__factory.connect(
//     config.Pools.PLP.poolDiamond,
//     deployer
//   );

//   await (
//     await poolDiamond.diamondCut(
//       facetCuts,
//       ethers.constants.AddressZero,
//       "0x",
//       { gasLimit: 100000000 }
//     )
//   ).wait();

//   console.log(`Execute diamondCut`);
// };

// export default func;
// func.tags = ["ExecuteDiamondCut"];
