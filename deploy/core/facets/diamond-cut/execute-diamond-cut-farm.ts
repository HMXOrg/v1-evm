import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DiamondCutFacet__factory,
  FarmFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const methods = [
  "farm(address,bool)",
  "setStrategyOf(address,address)",
  "setStrategyTargetBps(address,uint64)",
];

const facetCuts = [
  {
    facetAddress: config.Pools.PLP.facets.farm,
    action: FacetCutAction.Add,
    functionSelectors: methods.map((each) => {
      return FarmFacet__factory.createInterface().getSighash(each);
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

  console.log(`Execute diamondCut for FarmFacet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Farm"];
