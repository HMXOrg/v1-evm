import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  FeedableRewarder__factory,
  RewardDistributor__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const FEEDER: string = "0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const rewardDistributor = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );
  const tx = await rewardDistributor.setParams(
    config.Tokens.USDC,
    config.Pools.PLP.poolDiamond,
    config.PoolRouter,
    config.Staking.PLPStaking.rewarders[0].address,
    ethers.constants.AddressZero,
    await rewardDistributor.devFundBps(),
    await rewardDistributor.plpStakingBps(),
    await rewardDistributor.devFundAddress(),
    await rewardDistributor.merkleAirdrop(),
    { gasLimit: 10000000 }
  );
  const txReceipt = await tx.wait();
  console.log(`Executed setParams at RewardDistributor`);
  console.log(`Feeder: ${FEEDER}`);
};

export default func;
func.tags = ["SetRewardDistributorParams"];
