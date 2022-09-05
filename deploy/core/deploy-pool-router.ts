import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const WNATIVE = "0x9c3c9283d3e44854697cd22d3faa240cfb032889";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolRouter = await ethers.getContractFactory("PoolRouter", deployer);
  const poolRouter = await PoolRouter.deploy(WNATIVE);
  await poolRouter.deployed();
  console.log(`Deploying PoolRouter Contract`);
  console.log(`Deployed at: ${poolRouter.address}`);
};

export default func;
func.tags = ["PoolRouter"];
