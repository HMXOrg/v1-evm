import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const GetterFacet = await ethers.getContractFactory("GetterFacet", deployer);
  const getterFacet = await GetterFacet.deploy();
  await getterFacet.deployed();
  console.log(`Deploying GetterFacet Contract`);
  console.log(`Deployed at: ${getterFacet.address}`);

  await tenderly.verify({
    address: getterFacet.address,
    name: "GetterFacet",
  });

  config.Pools.PLP.facets.getter = getterFacet.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["GetterFacet"];
