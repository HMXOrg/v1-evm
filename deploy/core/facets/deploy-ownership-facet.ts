import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const OwnershipFacet = await ethers.getContractFactory(
    "OwnershipFacet",
    deployer
  );
  const ownershipFacet = await OwnershipFacet.deploy();
  await ownershipFacet.deployed();
  console.log(`Deploying OwnershipFacet Contract`);
  console.log(`Deployed at: ${ownershipFacet.address}`);

  config.Pools.PLP.facets.ownership = ownershipFacet.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: ownershipFacet.address,
    name: "OwnershipFacet",
  });
};

export default func;
func.tags = ["OwnershipFacet"];
