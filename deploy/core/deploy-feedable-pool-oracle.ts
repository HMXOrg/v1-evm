import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const FeedablePoolOracle = await ethers.getContractFactory(
    "FeedablePoolOracle",
    deployer
  );
  const feedablePoolOracle = await FeedablePoolOracle.deploy();
  await feedablePoolOracle.deployed();
  console.log(`Deploying FeedablePoolOracle Token Contract`);
  console.log(`Deployed at: ${feedablePoolOracle.address}`);

  await tenderly.verify({
    address: feedablePoolOracle.address,
    name: "FeedablePoolOracle",
  });

  config.Pools.PLP.oracle = feedablePoolOracle.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["FeedablePoolOracle"];
