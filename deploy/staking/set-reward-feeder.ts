import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FeedableRewarder__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const FEEDER: string = config.Staking.RewardDistributor.address;
const REWARDERS: string[] = [
  (
    config.Staking.PLPStaking.rewarders.find(
      (o) => o.name === "PLP Staking Protocol Revenue"
    ) as any
  ).address,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  for (const REWARDER of REWARDERS) {
    const rewarder = FeedableRewarder__factory.connect(REWARDER, deployer);
    const tx = await rewarder.setFeeder(FEEDER);
    const txReceipt = await tx.wait();
    console.log(`Executed setFeeder`);
    console.log(`Rewarder Contract: ${REWARDER}`);
    console.log(`Feeder: ${FEEDER}`);
  }
};

export default func;
func.tags = ["SetFeeder"];
