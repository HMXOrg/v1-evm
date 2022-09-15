import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const NAME = "Dragon Staking esP88 Emission";
const REWARD_TOKEN_ADDRESS = config.Tokens.esP88;
const STAKING_CONTRACT_ADDRESS = config.Staking.DragonStaking.address;

// CONSTANT DO NOT EDIT
const WMATIC = config.Tokens.WMATIC;

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
