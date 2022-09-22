import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

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

  const implAddress = await getImplementationAddress(
    ethers.provider,
    lockdrop.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "Lockdrop",
  });

  config.Lockdrop.lockdrops = config.Lockdrop.lockdrops.map((each: any) => {
    if (each.lockdropToken === lockdropToken) {
      return { ...each, address: lockdrop.address };
    } else return each;
  });
  writeConfigFile(config);
};

export default func;
func.tags = ["Lockdrop"];
