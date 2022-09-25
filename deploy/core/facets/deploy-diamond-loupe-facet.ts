import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DiamondLoupeFacet = await ethers.getContractFactory(
    "DiamondLoupeFacet",
    deployer
  );
  const diamondLoupeFacet = await DiamondLoupeFacet.deploy();
  diamondLoupeFacet.deployed();
  console.log(`Deploying DiamondLoupeFacet Contract`);
  console.log(`Deployed at: ${diamondLoupeFacet.address}`);

  config.Pools.PLP.facets.diamondLoupe = diamondLoupeFacet.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: diamondLoupeFacet.address,
    name: "DiamondLoupeFacet",
  });
};

export default func;
func.tags = ["DiamondLoupeFacet"];
