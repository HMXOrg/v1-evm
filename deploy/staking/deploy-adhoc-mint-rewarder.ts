import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const NAME = "Dragon Staking Dragon Point Emission";
const REWARD_TOKEN_ADDRESS = "0x20E58fC5E1ee3C596fb3ebD6de6040e7800e82E6";
const STAKING_CONTRACT_ADDRESS = "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d";

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
