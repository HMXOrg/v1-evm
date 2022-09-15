import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolConfigInitializer = await ethers.getContractFactory(
    "PoolConfigInitializer",
    deployer
  );
  console.log(`Deploying PoolConfigInitializer Contract`);
  const poolConfigInitializer = await PoolConfigInitializer.deploy();
  poolConfigInitializer.deployed();
  console.log(`Deployed at: ${poolConfigInitializer.address}`);
};

export default func;
func.tags = ["PoolConfigInitializer"];
