import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../utils/config";
import { RewardDistributor__factory } from "../../typechain";

const config = getConfig();

const tokenList = [
  config.Tokens.WMATIC,
  config.Tokens.WBTC,
  config.Tokens.WETH,
  config.Tokens.USDC,
  config.Tokens.USDT,
  config.Tokens.DAI,
];

const feedingExpiredAt = 1698339600;
const weekTimestamp = 2754;
const referralRevenueAmount = 4497234393;
const merkleRoot =
  "0xe8265d62c006291e55af5cc6cde08360d1362af700d61a06087c7ce21b2c31b8";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const rewardDistributor = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );
  await (
    await rewardDistributor.claimAndFeedProtocolRevenue(
      tokenList,
      feedingExpiredAt,
      weekTimestamp,
      referralRevenueAmount,
      merkleRoot,
      { gasLimit: 10000000 }
    )
  ).wait();
  console.log("Done");
};

export default func;
func.tags = ["ClaimAndFeedProtocolRevenue"];
