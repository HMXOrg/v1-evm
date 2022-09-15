import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const GetterFacet = await ethers.getContractFactory("GetterFacet", deployer);
  const getterFacet = await GetterFacet.deploy();
  getterFacet.deployed();
  console.log(`Deploying GetterFacet Contract`);
  console.log(`Deployed at: ${getterFacet.address}`);
};

export default func;
func.tags = ["GetterFacet"];
