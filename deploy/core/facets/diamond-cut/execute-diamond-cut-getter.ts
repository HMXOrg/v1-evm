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
import { eip1559rapidGas } from "../../../utils/gas";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const methods = [
  "accumFundingRateLong(address)",
  "accumFundingRateShort(address)",
  "additionalAum()",
  "approvedPlugins(address,address)",
  "borrowingRateFactor()",
  "convertTokensToUsde30(address,uint256,bool)",
  "discountedAum()",
  "feeReserveOf(address)",
  "fundingInterval()",
  "fundingRateFactor()",
  "getAddLiquidityFeeBps(address,uint256)",
  "getAum(bool)",
  "getAumE18(bool)",
  "getBorrowingFee(address,address,address,bool,uint256,uint256)",
  "getDelta(address,uint256,uint256,bool,uint256,int256,int256)",
  "getEntryBorrowingRate(address,address,bool)",
  "getEntryFundingRate(address,address,bool)",
  "getFundingFee(address,bool,uint256,int256)",
  "getFundingFeeAccounting()",
  "getNextBorrowingRate(address)",
  "getNextFundingRate(address)",
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
  "openInterestLong(address)",
  "openInterestShort(address)",
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
  "sumBorrowingRateOf(address)",
  "swapFeeBps()",
  "taxBps()",
  "tokenMetas(address)",
  "totalOf(address)",
  "totalTokenWeight()",
  "totalUsdDebt()",
  "usdDebtOf(address)",
  "getDeltaWithoutFundingFee(address,uint256,uint256,bool,uint256)",
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

  ethers.provider;

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  console.log(`> Diamond cutting getter facet`);
  const tx = await poolDiamond.diamondCut(
    facetCuts,
    ethers.constants.AddressZero,
    "0x",
    await eip1559rapidGas()
  );
  console.log(`> ⛓ Tx hash: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Getter"];
