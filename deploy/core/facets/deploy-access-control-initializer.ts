import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const AccessControlInitializer = await ethers.getContractFactory(
    "AccessControlInitializer",
    deployer
  );
  console.log(`Deploying AccessControlInitializer Contract`);
  const accessControlInitializer = await AccessControlInitializer.deploy();
  await accessControlInitializer.deployTransaction.wait(3);
  console.log(`Deployed at: ${accessControlInitializer.address}`);

  config.Pools.PLP.facets.accessControlInitializer =
    accessControlInitializer.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: accessControlInitializer.address,
    name: "AccessControlInitializer",
  });
};

export default func;
func.tags = ["AccessControlInitializer"];
