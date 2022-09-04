import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const fundingInterval = 60 * 60 * 8;
const mintBurnFeeBps = 30;
const taxBps = 50;
const stableFundingRateFactor = 600;
const fundingRateFactor = 600;
const liquidityCoolDownDuration = 0;
const liquidationFeeUsd = 0;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolConfig = await ethers.getContractFactory("PoolConfig", deployer);
  const poolConfig = await upgrades.deployProxy(PoolConfig, [
    fundingInterval,
    mintBurnFeeBps,
    taxBps,
    stableFundingRateFactor,
    fundingRateFactor,
    liquidityCoolDownDuration,
    liquidationFeeUsd,
  ]);
  await poolConfig.deployed();
  console.log(`Deploying PoolConfig Contract`);
  console.log(`Deployed at: ${poolConfig.address}`);
};

export default func;
func.tags = ["PoolConfig"];
