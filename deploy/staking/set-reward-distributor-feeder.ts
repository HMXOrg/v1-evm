import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  FeedableRewarder__factory,
  RewardDistributor__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const FEEDER: string = "0x1E0Fae3797C82D1C191aE6C9082bbDd04169fA0C";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const rewarder = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );
  console.log(`> Setting reward distributor feeder to ${FEEDER}`);
  const tx = await rewarder.setFeeder(FEEDER);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  tx.wait(3);
  console.log(`> Tx is mined`);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetRewardDistributorFeeder"];
