import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const REWARD_TOKEN: string = config.Tokens.WMATIC;
const POOL: string = config.Pools.PLP.poolDiamond;
const POOL_ROUTER: string = config.PoolRouter;
const PLP_STAKING_PROTOCOL_REVENUE_REWARDER: string = (
  config.Staking.PLPStaking.rewarders.find(
    (o) => o.name === "PLP Staking Protocol Revenue"
  ) as any
).address;
const DRAGON_STAKING_PROTOCOL_REVENUE_REWARDER: string = (
  config.Staking.DragonStaking.rewarders.find(
    (o) => o.name === "Dragon Staking Protocol Revenue"
  ) as any
).address;
const DEV_FUND_BPS: number = 1500; // 15%
const PLP_STAKING_BPS: number = 10000; // PLP -> 100%, Dragon -> 0%
const DEV_FUND_ADDRESS: string = "0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a";
const MERKLE_AIRDROP: string = config.MerkleAirdrop.address;
const REFERRAL_REVENUE_MAX_THRESHOLD: number = 3000; // 30%

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const RewardDistributor = await ethers.getContractFactory(
    "RewardDistributor",
    deployer
  );
  const rewardDistributor = await upgrades.deployProxy(RewardDistributor, [
    REWARD_TOKEN,
    POOL,
    POOL_ROUTER,
    PLP_STAKING_PROTOCOL_REVENUE_REWARDER,
    DRAGON_STAKING_PROTOCOL_REVENUE_REWARDER,
    DEV_FUND_BPS,
    PLP_STAKING_BPS,
    DEV_FUND_ADDRESS,
    MERKLE_AIRDROP,
    REFERRAL_REVENUE_MAX_THRESHOLD,
  ]);
  await rewardDistributor.deployed();
  console.log(`Deploying RewardDistributor Contract`);
  console.log(`Deployed at: ${rewardDistributor.address}`);

  config.Staking.RewardDistributor.address = rewardDistributor.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    rewardDistributor.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "RewardDistributor",
  });
};

export default func;
func.tags = ["RewardDistributor"];
