import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const NAME = "Dragon Staking esP88 Emission";
const REWARD_TOKEN_ADDRESS = getRewardTokenAddress(NAME);
const STAKING_CONTRACT_ADDRESS = getStakingContractAddress(NAME);

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

  const implAddress = await getImplementationAddress(
    ethers.provider,
    rewarder.address
  );

  await tenderly.verify({
    address: implAddress,
    name: contractName,
  });

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
  }
  writeConfigFile(config);
};

function getRewardTokenAddress(rewarderName: string): string {
  if (rewarderName.includes("Protocol Revenue")) {
    return config.Tokens.WMATIC;
  } else {
    return config.Tokens.esP88;
  }
}

function getStakingContractAddress(rewarderName: string): string {
  if (rewarderName.includes("Dragon Staking")) {
    return config.Staking.DragonStaking.address;
  } else {
    return config.Staking.PLPStaking.address;
  }
}

export default func;
func.tags = ["FeedableRewarder"];
