import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const OwnershipFacet = await ethers.getContractFactory(
    "OwnershipFacet",
    deployer
  );
  const ownershipFacet = await OwnershipFacet.deploy();
  ownershipFacet.deployed();
  console.log(`Deploying OwnershipFacet Contract`);
  console.log(`Deployed at: ${ownershipFacet.address}`);
};

export default func;
func.tags = ["OwnershipFacet"];
