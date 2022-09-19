import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const AdminFacet = await ethers.getContractFactory("AdminFacet", deployer);
  const adminFacet = await AdminFacet.deploy();
  adminFacet.deployed();
  console.log(`Deploying AdminFacet Contract`);
  console.log(`Deployed at: ${adminFacet.address}`);

  await tenderly.verify({
    address: adminFacet.address,
    name: "AdminFacet",
  });

  config.Pools.PLP.facets.admin = adminFacet.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["AdminFacet"];
