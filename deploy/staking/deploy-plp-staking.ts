import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PLPStaking = await ethers.getContractFactory("PLPStaking", deployer);
  const plpStaking = await upgrades.deployProxy(PLPStaking, []);
  await plpStaking.deployed();
  console.log(`Deploying PLPStaking Contract`);
  console.log(`Deployed at: ${plpStaking.address}`);
};

export default func;
func.tags = ["PLPStaking"];
