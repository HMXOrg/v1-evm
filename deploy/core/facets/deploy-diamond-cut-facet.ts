import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DiamondCutFacet = await ethers.getContractFactory(
    "DiamondCutFacet",
    deployer
  );

  console.log(`Deploying DiamondCutFacet Contract`);
  const diamondCutFacet = await DiamondCutFacet.deploy();
  diamondCutFacet.deployed();
  console.log(`Deployed at: ${diamondCutFacet.address}`);
};

export default func;
func.tags = ["DiamondCutFacet"];
