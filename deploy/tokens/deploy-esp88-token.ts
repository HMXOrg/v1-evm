import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const EsP88 = await ethers.getContractFactory("EsP88", deployer);
  const esP88 = await EsP88.deploy();
  console.log(`Deploying EsP88 Token Contract`);
  console.log(`Deployed at: ${esP88.address}`);
};

export default func;
func.tags = ["EsP88Token"];
