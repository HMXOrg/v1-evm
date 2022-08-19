import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { BaseStaking__factory } from "../../typechain";

const STAKING_CONTRACT_ADDRESS = "0xb7c634ceeC4F86Da390d563FE46a7AF6879Bdc82";
const STAKING_TOKEN_ADDRESS = "0x79F87112d902fCa835Df3b210fa0F9d1ACcEf131";
const REWARDERS = [
  "0x67284cEF8F608b64Aba0e44EC5d6cfBaFc26F758",
  "0x108d83658bD43C9e427C64238EF7d79912dbb2fA",
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const stakingContract = BaseStaking__factory.connect(
    STAKING_CONTRACT_ADDRESS,
    deployer
  );
  const tx = await stakingContract.addStakingToken(
    STAKING_TOKEN_ADDRESS,
    REWARDERS
  );
  const txReceipt = await tx.wait();
  console.log(`Execute  addStakingToken`);
  console.log(`Staking Token: ${STAKING_TOKEN_ADDRESS}`);
  console.log(`Rewarders: ${REWARDERS}`);
};

export default func;
func.tags = ["AddStakingToken"];
