import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const WNATIVE = config.Tokens.WMATIC;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolRouter = await ethers.getContractFactory("PoolRouter02", deployer);
  const poolRouter = await PoolRouter.deploy(
    WNATIVE,
    config.Staking.PLPStaking.address
  );
  await poolRouter.deployed();
  console.log(`Deploying PoolRouter02 Contract`);
  console.log(`Deployed at: ${poolRouter.address}`);

  config.PoolRouter = poolRouter.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: poolRouter.address,
    name: "PoolRouter02",
  });
};

export default func;
func.tags = ["PoolRouter02"];
