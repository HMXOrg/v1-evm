import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const MultiplierPointToken = await ethers.getContractFactory(
    "MultiplierPointToken",
    deployer
  );
  const multiplierPointToken = await MultiplierPointToken.deploy();
  console.log(`Deploying MultiplierPoint Token Contract`);
  console.log(`Deployed at: ${multiplierPointToken.address}`);
};

export default func;
func.tags = ["MultiplierPointToken"];
