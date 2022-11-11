import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const minDelay = 60 * 60; // 1 hr
const proposers = ["0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a"];
const executors = ["0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a"];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const TimelockController = await ethers.getContractFactory(
    "TimelockController",
    deployer
  );
  const timelockController = await TimelockController.deploy(
    minDelay,
    proposers,
    executors
  );
  await timelockController.deployed();
  console.log(`Deploying TimelockController Contract`);
  console.log(`Deployed at: ${timelockController.address}`);

  config.TimelockController = timelockController.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: timelockController.address,
    name: "TimelockController",
  });
};

export default func;
func.tags = ["TimelockController"];
