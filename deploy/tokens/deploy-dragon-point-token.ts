import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DragonPoint = await ethers.getContractFactory("DragonPoint", deployer);
  const dragonPoint = await DragonPoint.deploy();
  console.log(`Deploying DragonPoint Token Contract`);
  console.log(`Deployed at: ${dragonPoint.address}`);
};

export default func;
func.tags = ["DragonPointToken"];
