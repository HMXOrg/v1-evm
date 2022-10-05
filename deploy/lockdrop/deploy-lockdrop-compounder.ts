import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const esp88Token = config.Tokens.esP88;
const dragonStaking = config.Staking.DragonStaking.address;
const revenueToken = config.Tokens.USDC;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LockdropCompounder = await ethers.getContractFactory(
    "LockdropCompounder",
    deployer
  );
  const lockdropCompounder = await upgrades.deployProxy(LockdropCompounder, [
    esp88Token,
    dragonStaking,
    revenueToken,
  ]);
  await lockdropCompounder.deployed();
  console.log(`Deploying LockdropCompounder Contract`);
  console.log(`Deployed at: ${lockdropCompounder.address}`);

  config.Lockdrop.compounder = lockdropCompounder.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    lockdropCompounder.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "LockdropCompounder",
  });
};

export default func;
func.tags = ["LockdropCompounder"];
