import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const NAME = "PLP Staking Protocol Revenue";
const REWARD_TOKEN_ADDRESS = getRewardTokenAddress(NAME);
const STAKING_CONTRACT_ADDRESS = getStakingContractAddress(NAME);

// CONSTANT DO NOT EDIT
const WMATIC = config.Tokens.WMATIC;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const isNative = REWARD_TOKEN_ADDRESS.toLowerCase() === WMATIC.toLowerCase();
  const contractName = isNative ? "WFeedableRewarder" : "FeedableRewarder";
  const Rewarder = await ethers.getContractFactory(contractName, deployer);

  console.log(`> Deploying ${NAME} ${contractName} Contract`);
  const rewarder = await upgrades.deployProxy(Rewarder, [
    NAME,
    REWARD_TOKEN_ADDRESS,
    STAKING_CONTRACT_ADDRESS,
  ]);
  console.log(`> ⛓ Tx submitted: ${rewarder.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await rewarder.deployTransaction.wait(3);
  console.log(`> Tx mined!`);
  console.log(`> Deployed at: ${rewarder.address}`);

  if (NAME.includes("PLP")) {
    config.Staking.PLPStaking.rewarders =
      config.Staking.PLPStaking.rewarders.map((each: any) => {
        if (each.name === NAME) {
          return {
            ...each,
            address: rewarder.address,
            rewardToken: REWARD_TOKEN_ADDRESS,
          };
        } else return each;
      });
  } else if (NAME.includes("Dragon Staking")) {
    config.Staking.DragonStaking.rewarders =
      config.Staking.DragonStaking.rewarders.map((each: any) => {
        if (each.name === NAME) {
          return {
            ...each,
            address: rewarder.address,
            rewardToken: REWARD_TOKEN_ADDRESS,
          };
        } else return each;
      });
  } else if (NAME.includes("P88 LP Staking")) {
    config.Staking.P88LPStaking.rewarders =
      config.Staking.P88LPStaking.rewarders.map((each: any) => {
        if (each.name === NAME) {
          return {
            ...each,
            address: rewarder.address,
            rewardToken: REWARD_TOKEN_ADDRESS,
          };
        } else return each;
      });
  }
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    rewarder.address
  );

  console.log(`> Verifying contract on Tenderly`);
  await tenderly.verify({
    address: implAddress,
    name: contractName,
  });
  console.log(`> ✅ Verified!`);
};

function getRewardTokenAddress(rewarderName: string): string {
  if (rewarderName.includes("Protocol Revenue")) {
    return config.Tokens.USDC;
  } else {
    return config.Tokens.esP88;
  }
}

function getStakingContractAddress(rewarderName: string): string {
  if (rewarderName.includes("Dragon Staking")) {
    return config.Staking.DragonStaking.address;
  } else if (rewarderName.includes("P88 LP Staking")) {
    return config.Staking.P88LPStaking.address;
  } else {
    return config.Staking.PLPStaking.address;
  }
}

export default func;
func.tags = ["FeedableRewarder"];
