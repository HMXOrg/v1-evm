import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const P88 = await ethers.getContractFactory("P88", deployer);
  const p88 = await P88.deploy();
  console.log(`Deploying P88 Token Contract`);
  console.log(`Deployed at: ${p88.address}`);
};

export default func;
func.tags = ["P88Token"];
