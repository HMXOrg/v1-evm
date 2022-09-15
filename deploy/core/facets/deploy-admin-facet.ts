import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const AdminFacet = await ethers.getContractFactory("AdminFacet", deployer);
  const adminFacet = await AdminFacet.deploy();
  adminFacet.deployed();
  console.log(`Deploying AdminFacet Contract`);
  console.log(`Deployed at: ${adminFacet.address}`);
};

export default func;
func.tags = ["AdminFacet"];
