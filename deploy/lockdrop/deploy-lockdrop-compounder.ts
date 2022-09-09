import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const esp88Token = config.Tokens.esP88;
const dragonStaking = config.Staking.DragonStaking.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LockdropCompounder = await ethers.getContractFactory(
    "LockdropCompounder",
    deployer
  );
  const lockdropCompounder = await upgrades.deployProxy(LockdropCompounder, [
    esp88Token,
    dragonStaking,
  ]);
  await lockdropCompounder.deployed();
  console.log(`Deploying LockdropCompounder Contract`);
  console.log(`Deployed at: ${lockdropCompounder.address}`);
};

export default func;
func.tags = ["LockdropCompounder"];
