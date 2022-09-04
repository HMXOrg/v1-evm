import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const roundDepth = 3;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolOracle = await ethers.getContractFactory("PoolOracle", deployer);
  const poolOracle = await upgrades.deployProxy(PoolOracle, [roundDepth]);
  await poolOracle.deployed();
  console.log(`Deploying PoolOracle Contract`);
  console.log(`Deployed at: ${poolOracle.address}`);
};

export default func;
func.tags = ["PoolOracle"];
