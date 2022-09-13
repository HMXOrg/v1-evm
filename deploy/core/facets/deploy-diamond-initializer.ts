import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DiamondInitializer = await ethers.getContractFactory(
    "DiamondInitializer",
    deployer
  );
  console.log(`Deploying DiamondInitializer Contract`);
  const diamondInitializer = await DiamondInitializer.deploy();
  diamondInitializer.deployed();
  console.log(`Deployed at: ${diamondInitializer.address}`);
};

export default func;
func.tags = ["DiamondInitializer"];
