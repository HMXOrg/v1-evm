import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const startLockTimestamp = 1664940600;
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

  config.Lockdrop.config = lockdropConfig.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    lockdropConfig.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "LockdropConfig",
  });
};

export default func;
func.tags = ["LockdropConfig"];
