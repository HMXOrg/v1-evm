import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const NAME = "Dragon Staking Dragon Point Emission";
const REWARD_TOKEN_ADDRESS = "0x79F87112d902fCa835Df3b210fa0F9d1ACcEf131";
const STAKING_CONTRACT_ADDRESS = "0xb7c634ceeC4F86Da390d563FE46a7AF6879Bdc82";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Rewarder = await ethers.getContractFactory(
    "AdHocMintRewarder",
    deployer
  );
  const rewarder = await Rewarder.deploy(
    NAME,
    REWARD_TOKEN_ADDRESS,
    STAKING_CONTRACT_ADDRESS
  );
  console.log(`Deploying ${NAME} AdHocMintRewarder Contract`);
  console.log(`Deployed at: ${rewarder.address}`);
};

export default func;
func.tags = ["AdHocMintRewarder"];
