import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { RewardDistributor__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

interface RewardDistributorSetParamsArgs {
  rewardToken?: string;
  pool?: string;
  poolRouter?: string;
  plpStakingProtocolRevenue?: string;
  dragonStakingProtocolRevenue?: string;
  devFundBps?: string;
  plpStakingBps?: string;
  devFundAddress?: string;
  merkleAirdrop?: string;
}

const args: RewardDistributorSetParamsArgs = {
  devFundAddress: "0xcf0D151f84dCa261b1d201b04cDe24227Aa181F6",
};

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const config = getConfig();

  const rewardDistributor = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );

  const [
    prevRewardToken,
    prevPool,
    prevPoolRouter,
    prevPlpStakingProtocolRevenue,
    prevDragonStakingProtocolRevenue,
    prevDevFundBps,
    prevPlpStakingBps,
    prevDevFundAddress,
    prevMerkleAirdrop,
  ] = await Promise.all([
    await rewardDistributor.rewardToken(),
    await rewardDistributor.pool(),
    await rewardDistributor.poolRouter(),
    await rewardDistributor.plpStakingProtocolRevenueRewarder(),
    await rewardDistributor.dragonStakingProtocolRevenueRewarder(),
    await rewardDistributor.devFundBps(),
    await rewardDistributor.plpStakingBps(),
    await rewardDistributor.devFundAddress(),
    await rewardDistributor.merkleAirdrop(),
  ]);

  console.log(`> Setting reward distributor params`);
  const tx = await rewardDistributor.setParams(
    args.rewardToken || prevRewardToken,
    args.pool || prevPool,
    args.poolRouter || prevPoolRouter,
    args.plpStakingProtocolRevenue || prevPlpStakingProtocolRevenue,
    args.dragonStakingProtocolRevenue || prevDragonStakingProtocolRevenue,
    args.devFundBps || prevDevFundBps,
    args.plpStakingBps || prevPlpStakingBps,
    args.devFundAddress || prevDevFundAddress,
    args.merkleAirdrop || prevMerkleAirdrop,
    await eip1559rapidGas()
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  tx.wait(3);
  console.log(`> Tx is mined`);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetRewardDistributorParams"];
