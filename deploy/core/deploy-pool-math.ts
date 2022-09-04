import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolMath = await ethers.getContractFactory("PoolMath", deployer);
  const poolMath = await PoolMath.deploy();
  console.log(`Deploying PoolMath Contract`);
  console.log(`Deployed at: ${poolMath.address}`);
};

export default func;
func.tags = ["PoolMath"];
