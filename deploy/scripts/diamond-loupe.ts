import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { DiamondLoupeFacet__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const diamondLoupe = DiamondLoupeFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );
  console.log(
    await diamondLoupe.facetFunctionSelectors(config.Pools.PLP.facets.getter)
  );
};

export default func;
func.tags = ["DiamondLoupeRead"];
