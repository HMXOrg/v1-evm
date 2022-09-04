import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const lockdropToken = "";
const pool = "";
const lockdropConfig = "";
const rewardTokens: any[] = [];
const nativeTokenAddress = "";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Lockdrop = await ethers.getContractFactory("Lockdrop", deployer);
  const lockdrop = await upgrades.deployProxy(Lockdrop, [
    lockdropToken,
    pool,
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
