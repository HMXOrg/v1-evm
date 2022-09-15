import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const FundingRateFacet = await ethers.getContractFactory(
    "FundingRateFacet",
    deployer
  );
  const fundingRateFacet = await FundingRateFacet.deploy();
  fundingRateFacet.deployed();
  console.log(`Deploying FundingRateFacet Contract`);
  console.log(`Deployed at: ${fundingRateFacet.address}`);
};

export default func;
func.tags = ["FundingRateFacet"];
