import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const NAME = "Dragon Staking esP88 Emission";
const REWARD_TOKEN_ADDRESS = "0xEB27B05178515c7E6E51dEE159c8487A011ac030";
const STAKING_CONTRACT_ADDRESS = "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d";

// CONSTANT DO NOT EDIT
const WMATIC = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const isNative = REWARD_TOKEN_ADDRESS.toLowerCase() === WMATIC.toLowerCase();
  const contractName = isNative ? "WFeedableRewarder" : "FeedableRewarder";
  const Rewarder = await ethers.getContractFactory(contractName, deployer);
  const rewarder = await upgrades.deployProxy(Rewarder, [
    NAME,
    REWARD_TOKEN_ADDRESS,
    STAKING_CONTRACT_ADDRESS,
  ]);
  await rewarder.deployed();
  console.log(`Deploying ${NAME} ${contractName} Contract`);
  console.log(`Deployed at: ${rewarder.address}`);
};

export default func;
func.tags = ["FeedableRewarder"];
