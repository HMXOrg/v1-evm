import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLPStaking__factory } from "../../typechain";

const STAKING_CONTRACT_ADDRESS = "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d";
const STAKING_TOKEN_ADDRESS = "0x20E58fC5E1ee3C596fb3ebD6de6040e7800e82E6";
const REWARDERS = [
  "0x28826219ffb76aa41a56a40e875709391795e512",
  "0x3f78cEc168AdF9242a3d2F04A0ab1E312c26b3Ec",
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
