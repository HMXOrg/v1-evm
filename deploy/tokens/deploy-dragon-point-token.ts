import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DragonPoint = await ethers.getContractFactory("DragonPoint", deployer);
  const dragonPoint = await DragonPoint.deploy();
  console.log(`Deploying DragonPoint Token Contract`);
  console.log(`Deployed at: ${dragonPoint.address}`);

  await tenderly.verify({
    address: dragonPoint.address,
    name: "DragonPoint",
  });

  config.Tokens.DragonPoint = dragonPoint.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["DragonPointToken"];
