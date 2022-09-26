import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const FarmFacet = await ethers.getContractFactory("FarmFacet", deployer);
  const farmFacet = await FarmFacet.deploy();
  farmFacet.deployed();
  console.log(`Deploying FarmFacet Contract`);
  console.log(`Deployed at: ${farmFacet.address}`);

  config.Pools.PLP.facets.farm = farmFacet.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: farmFacet.address,
    name: "FarmFacet",
  });
};

export default func;
func.tags = ["FarmFacet"];
