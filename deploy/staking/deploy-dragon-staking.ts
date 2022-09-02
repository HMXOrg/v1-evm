import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const DRAGON_POINT_TOKEN_ADDRESS = "0x20E58fC5E1ee3C596fb3ebD6de6040e7800e82E6";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DragonStaking = await ethers.getContractFactory(
    "DragonStaking",
    deployer
  );
  const dragonStaking = await upgrades.deployProxy(DragonStaking, [
    DRAGON_POINT_TOKEN_ADDRESS,
  ]);
  await dragonStaking.deployed();
  console.log(`Deploying DragonStaking Contract`);
  console.log(`Deployed at: ${dragonStaking.address}`);
};

export default func;
func.tags = ["DragonStaking"];
