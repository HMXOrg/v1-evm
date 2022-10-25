import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AccessControlInitializer__factory,
  DiamondCutFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();
const ADMIN = "0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a";

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  await (
    await poolDiamond.diamondCut(
      [],
      config.Pools.PLP.facets.accessControlInitializer,
      AccessControlInitializer__factory.createInterface().encodeFunctionData(
        "initialize",
        [ADMIN]
      )
    )
  ).wait();

  console.log(`Execute diamondCut for InitializeAccessControl`);
};

export default func;
func.tags = ["ExecuteDiamondCut-InitializeAccessControl"];
