import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly, network } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DragonPoint = await ethers.getContractFactory("DragonPoint", deployer);
  const dragonPoint = await upgrades.deployProxy(DragonPoint);
  await dragonPoint.deployed();
  console.log(`Deploying DragonPoint Token Contract`);
  console.log(`Deployed at: ${dragonPoint.address}`);

  config.Tokens.DragonPoint = dragonPoint.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    network.provider,
    dragonPoint.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "DragonPoint",
  });
};

export default func;
func.tags = ["DragonPointToken"];
