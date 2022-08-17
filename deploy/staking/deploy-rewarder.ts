import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const NAME = "Dragon Staking esP88 Emission";
const REWARD_TOKEN_ADDRESS = "0xB0897464c0b0C400052fD292Db28A2942df1e705";
const STAKING_CONTRACT_ADDRESS = "0x0E730e690E6C4ccE1ea932eE227575E35ee4a2F7";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Rewarder = await ethers.getContractFactory("Rewarder", deployer);
  const rewarder = await Rewarder.deploy(
    NAME,
    REWARD_TOKEN_ADDRESS,
    STAKING_CONTRACT_ADDRESS
  );
  console.log(`Deploying ${NAME} Rewarder Contract`);
  console.log(`Deployed at: ${rewarder.address}`);
};

export default func;
func.tags = ["Rewarder"];
