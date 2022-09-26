import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AdminFacet__factory,
  DiamondCutFacet__factory,
  DiamondLoupeFacet__factory,
  FundingRateFacet__factory,
  GetterFacet__factory,
  LiquidityFacetInterface__factory,
  OwnershipFacet__factory,
  PerpTradeFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const methods = [
  "additionalAum()",
  "approvedPlugins(address,address)",
  "discountedAum()",
  "feeReserveOf(address)",
  "fundingInterval()",
  "borrowingRateFactor()",
  "getAddLiquidityFeeBps(address,uint256)",
  "getAum(bool)",
  "getAumE18(bool)",
  "getDelta(address,uint256,uint256,bool,uint256)",
  "getEntryBorrowingRate(address,address,bool)",
  "getBorrowingFee(address,address,address,bool,uint256,uint256)",
  "getNextBorrowingRate(address)",
  "getNextShortAveragePrice(address,uint256,uint256)",
  "getPoolShortDelta(address)",
  "getPosition(address,address,address,bool)",
  "getPositionDelta(address,uint256,address,address,bool)",
  "getPositionFee(address,address,address,bool,uint256)",
  "getPositionLeverage(address,uint256,address,address,bool)",
  "getPositionNextAveragePrice(address,uint256,uint256,bool,uint256,uint256,uint256)",
  "getPositionWithSubAccountId(address,uint256,address,address,bool)",
  "getRedemptionCollateral(address)",
  "getRedemptionCollateralUsd(address)",
  "getRemoveLiquidityFeeBps(address,uint256)",
  "getStrategyDeltaOf(address)",
  "getSubAccount(address,uint256)",
  "getSwapFeeBps(address,address,uint256)",
  "getTargetValue(address)",
  "guaranteedUsdOf(address)",
  "isAllowAllLiquidators()",
  "isAllowedLiquidators(address)",
  "isDynamicFeeEnable()",
  "isLeverageEnable()",
  "isSwapEnable()",
  "lastFundingTimeOf(address)",
  "liquidationFeeUsd()",
  "liquidityOf(address)",
  "maxLeverage()",
  "minProfitDuration()",
  "mintBurnFeeBps()",
  "oracle()",
  "pendingStrategyOf(address)",
  "plp()",
  "positionFeeBps()",
  "reservedOf(address)",
  "router()",
  "shortAveragePriceOf(address)",
  "shortSizeOf(address)",
  "stableBorrowingRateFactor()",
  "stableSwapFeeBps()",
  "stableTaxBps()",
  "strategyDataOf(address)",
  "strategyOf(address)",
  "swapFeeBps()",
  "taxBps()",
  "tokenMetas(address)",
  "totalOf(address)",
  "totalTokenWeight()",
  "totalUsdDebt()",
  "usdDebtOf(address)",
];

const facetCuts = [
  {
    facetAddress: config.Pools.PLP.facets.getter,
    action: FacetCutAction.Add,
    functionSelectors: methods.map((each) => {
      return GetterFacet__factory.createInterface().getSighash(each);
    }),
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  await (
    await poolDiamond.diamondCut(facetCuts, ethers.constants.AddressZero, "0x")
  ).wait();

  console.log(`Execute diamondCut for GetterFacet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Getter"];
