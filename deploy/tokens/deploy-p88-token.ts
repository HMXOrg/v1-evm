import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const P88 = await ethers.getContractFactory("P88", deployer);
  const p88 = await P88.deploy(false);
  await p88.deployed();
  console.log(`Deploying P88 Token Contract`);
  console.log(`Deployed at: ${p88.address}`);

  await tenderly.verify({
    address: p88.address,
    name: "P88",
  });

  config.Tokens.P88 = p88.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["P88Token"];
