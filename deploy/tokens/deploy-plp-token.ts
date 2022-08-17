import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PLP = await ethers.getContractFactory("PLP", deployer);
  const plp = await PLP.deploy();
  console.log(`Deploying PLP Token Contract`);
  console.log(`Deployed at: ${plp.address}`);
};

export default func;
func.tags = ["PLPToken"];
