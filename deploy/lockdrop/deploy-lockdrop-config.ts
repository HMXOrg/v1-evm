import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const startLockTimestamp = 1662705000;
const plpStaking = config.Staking.PLPStaking.address;
const plpToken = config.Tokens.PLP;
const p88Token = config.Tokens.P88;
const gatewayAddress = config.Lockdrop.gateway;
const lockdropCompounder = config.Lockdrop.compounder;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LockdropConfig = await ethers.getContractFactory(
    "LockdropConfig",
    deployer
  );
  const lockdropConfig = await upgrades.deployProxy(LockdropConfig, [
    startLockTimestamp,
    plpStaking,
    plpToken,
    p88Token,
    gatewayAddress,
    lockdropCompounder,
  ]);
  await lockdropConfig.deployed();
  console.log(`Deploying LockdropConfig Contract`);
  console.log(`Deployed at: ${lockdropConfig.address}`);
};

export default func;
func.tags = ["LockdropConfig"];
