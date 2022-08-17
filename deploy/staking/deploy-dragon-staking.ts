import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const DRAGON_POINT_TOKEN_ADDRESS = "0x79F87112d902fCa835Df3b210fa0F9d1ACcEf131";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DragonStaking = await ethers.getContractFactory(
    "DragonStaking",
    deployer
  );
  const dragonStaking = await DragonStaking.deploy(DRAGON_POINT_TOKEN_ADDRESS);
  console.log(`Deploying DragonStaking Contract`);
  console.log(`Deployed at: ${dragonStaking.address}`);
};

export default func;
func.tags = ["DragonStaking"];
