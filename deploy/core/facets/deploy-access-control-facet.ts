import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const AccessControlFacet = await ethers.getContractFactory(
    "AccessControlFacet",
    deployer
  );
  const accessControlFacet = await AccessControlFacet.deploy();
  console.log(`Deploying AccessControlFacet Contract`);
  await accessControlFacet.deployTransaction.wait(3);
  console.log(`Deployed at: ${accessControlFacet.address}`);

  config.Pools.PLP.facets.accessControl = accessControlFacet.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: accessControlFacet.address,
    name: "AccessControlFacet",
  });
};

export default func;
func.tags = ["AccessControlFacet"];
