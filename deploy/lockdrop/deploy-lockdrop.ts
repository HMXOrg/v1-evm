import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const lockdropToken = config.Tokens.USDT;
const pool = config.Pools.PLP.poolDiamond;
const poolRouter = config.PoolRouter;
const lockdropConfig = config.Lockdrop.config;
const rewardTokens: any[] = [config.Tokens.WMATIC, config.Tokens.esP88];
const nativeTokenAddress = config.Tokens.WMATIC;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Lockdrop = await ethers.getContractFactory("Lockdrop", deployer);
  const lockdrop = await upgrades.deployProxy(Lockdrop, [
    lockdropToken,
    pool,
    poolRouter,
    lockdropConfig,
    rewardTokens,
    nativeTokenAddress,
  ]);
  await lockdrop.deployed();
  console.log(`Deploying Lockdrop Contract`);
  console.log(`Deployed at: ${lockdrop.address}`);
};

export default func;
func.tags = ["Lockdrop"];
