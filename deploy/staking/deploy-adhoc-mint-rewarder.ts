import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const NAME = "Dragon Staking Dragon Point Emission";
const REWARD_TOKEN_ADDRESS = config.Tokens.DragonPoint;
const STAKING_CONTRACT_ADDRESS = config.Staking.DragonStaking.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Rewarder = await ethers.getContractFactory(
    "AdHocMintRewarder",
    deployer
  );
  const rewarder = await upgrades.deployProxy(Rewarder, [
    NAME,
    REWARD_TOKEN_ADDRESS,
    STAKING_CONTRACT_ADDRESS,
  ]);
  await rewarder.deployed();
  console.log(`Deploying ${NAME} AdHocMintRewarder Contract`);
  console.log(`Deployed at: ${rewarder.address}`);
};

export default func;
func.tags = ["AdHocMintRewarder"];
