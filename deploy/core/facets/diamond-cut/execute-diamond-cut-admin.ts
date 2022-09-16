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
  "deleteTokenConfig(address)",
  "setAllowLiquidators(address[],bool)",
  "setFundingRate(uint64,uint64,uint64)",
  "setIsAllowAllLiquidators(bool)",
  "setIsDynamicFeeEnable(bool)",
  "setIsLeverageEnable(bool)",
  "setIsSwapEnable(bool)",
  "setLiquidationFeeUsd(uint256)",
  "setMaxLeverage(uint64)",
  "setMinProfitDuration(uint64)",
  "setMintBurnFeeBps(uint64)",
  "setPoolOracle(address)",
  "setPositionFeeBps(uint64)",
  "setRouter(address)",
  "setSwapFeeBps(uint64,uint64)",
  "setTaxBps(uint64,uint64)",
  "setTokenConfigs(address[],(bool,bool,bool,uint8,uint64,uint64,uint256,uint256,uint256)[])",
  "setTreasury(address)",
  "withdrawFeeReserve(address,address,uint256)",
];

const facetCuts = [
  {
    facetAddress: config.Pools.PLP.facets.admin,
    action: FacetCutAction.Add,
    functionSelectors: methods.map((each) => {
      return AdminFacet__factory.createInterface().getSighash(each);
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

  console.log(`Execute diamondCut for AdminFacet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Admin"];
