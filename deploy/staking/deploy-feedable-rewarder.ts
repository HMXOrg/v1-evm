import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const NAME = "Dragon Staking esP88 Emission";
const REWARD_TOKEN_ADDRESS = "0x980cDd680Ea324ABaa6C64df31fDA73e35aC6c90";
const STAKING_CONTRACT_ADDRESS = "0xB0897464c0b0C400052fD292Db28A2942df1e705";

// CONSTANT DO NOT EDIT
const WMATIC = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const isNative = REWARD_TOKEN_ADDRESS.toLowerCase() === WMATIC.toLowerCase();
  const contractName = isNative ? "WFeedableRewarder" : "FeedableRewarder";
  const Rewarder = await ethers.getContractFactory(contractName, deployer);
  const rewarder = await Rewarder.deploy(
    NAME,
    REWARD_TOKEN_ADDRESS,
    STAKING_CONTRACT_ADDRESS
  );
  console.log(`Deploying ${NAME} ${contractName} Contract`);
  console.log(`Deployed at: ${rewarder.address}`);
};

export default func;
func.tags = ["FeedableRewarder"];
