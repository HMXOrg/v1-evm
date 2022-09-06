import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const lockdropToken = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f";
const pool = "0x5A11B2328862527151fD2e7EaE02455E2e6b1d31";
const lockdropConfig = "0xfdae5977d844F3eA33B1d7c5cC947F6D110A4CD2";
const rewardTokens: any[] = [
  "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
  "0xEB27B05178515c7E6E51dEE159c8487A011ac030",
];
const nativeTokenAddress = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";

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
