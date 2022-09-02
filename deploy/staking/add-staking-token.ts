import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLPStaking__factory } from "../../typechain";

const STAKING_CONTRACT_ADDRESS = "0x7AAF085e43f059105F7e1ECc525E8142fF962159";
const STAKING_TOKEN_ADDRESS = "0xc88322Ec9526A7A98B7F58ff773b3B003C91ce71";
const REWARDERS = [
  "0xFc41505F4e24345E3797b6730a948a2B03a5eC5e",
  "0x417B34E90990657BF6adC1Ecc2ac4B36069cc927",
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const stakingContract = PLPStaking__factory.connect(
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
