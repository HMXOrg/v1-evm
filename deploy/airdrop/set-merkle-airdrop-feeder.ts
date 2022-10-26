import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MerkleAirdrop__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const FEEDER: string = config.Staking.RewardDistributor.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const rewarder = MerkleAirdrop__factory.connect(
    config.MerkleAirdrop.address,
    deployer
  );
  const tx = await rewarder.setFeeder(FEEDER);
  const txReceipt = await tx.wait();
  console.log(`Executed setFeeder at MerkleAirdrop`);
  console.log(`Feeder: ${FEEDER}`);
};

export default func;
func.tags = ["SetMerkleAirdropFeeder"];
