import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DiamondInitializer = await ethers.getContractFactory(
    "DiamondInitializer",
    deployer
  );
  console.log(`Deploying DiamondInitializer Contract`);
  const diamondInitializer = await DiamondInitializer.deploy();
  await diamondInitializer.deployed();
  console.log(`Deployed at: ${diamondInitializer.address}`);

  await tenderly.verify({
    address: diamondInitializer.address,
    name: "DiamondInitializer",
  });

  config.Pools.PLP.facets.diamondInitializer = diamondInitializer.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["DiamondInitializer"];
