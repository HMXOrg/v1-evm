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

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const rewardDistributor = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );
  await (await rewardDistributor.claimAndSwap(tokenList)).wait();
  console.log("Done");
};

export default func;
func.tags = ["ClaimAndSwap"];
