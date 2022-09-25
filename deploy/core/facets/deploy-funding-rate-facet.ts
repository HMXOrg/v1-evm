import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const FundingRateFacet = await ethers.getContractFactory(
    "FundingRateFacet",
    deployer
  );
  const fundingRateFacet = await FundingRateFacet.deploy();
  await fundingRateFacet.deployed();
  console.log(`Deploying FundingRateFacet Contract`);
  console.log(`Deployed at: ${fundingRateFacet.address}`);

  config.Pools.PLP.facets.fundingRate = fundingRateFacet.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: fundingRateFacet.address,
    name: "FundingRateFacet",
  });
};

export default func;
func.tags = ["FundingRateFacet"];
