import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AccessControlFacet__factory,
  DiamondCutFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const methods = [
  "getRoleAdmin(bytes32)",
  "grantRole(bytes32,address)",
  "hasRole(bytes32,address)",
  "renounceRole(bytes32,address)",
  "revokeRole(bytes32,address)",
];

const facetCuts = [
  {
    facetAddress: config.Pools.PLP.facets.accessControl,
    action: FacetCutAction.Add,
    functionSelectors: methods.map((each) => {
      return AccessControlFacet__factory.createInterface().getSighash(each);
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

  console.log(`Execute diamondCut for AccessControlFacet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-AccessControl"];
