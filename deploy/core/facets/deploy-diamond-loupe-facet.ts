import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DiamondLoupeFacet = await ethers.getContractFactory(
    "DiamondLoupeFacet",
    deployer
  );
  const diamondLoupeFacet = await DiamondLoupeFacet.deploy();
  diamondLoupeFacet.deployed();
  console.log(`Deploying DiamondLoupeFacet Contract`);
  console.log(`Deployed at: ${diamondLoupeFacet.address}`);
};

export default func;
func.tags = ["DiamondLoupeFacet"];
