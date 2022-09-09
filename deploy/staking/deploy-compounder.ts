import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const DRAGON_POINT = config.Tokens.DragonPoint;
const DESTINATION_COMPUND_POOL = config.Staking.DragonStaking.address;
const TOKENS = [config.Tokens.esP88, config.Tokens.DragonPoint];
const IS_COMPOUNDABLE_TOKENS = [true, true];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Compounder = await ethers.getContractFactory("Compounder", deployer);
  const compounder = await upgrades.deployProxy(Compounder, [
    DRAGON_POINT,
    DESTINATION_COMPUND_POOL,
    TOKENS,
    IS_COMPOUNDABLE_TOKENS,
  ]);
  await compounder.deployed();
  console.log(`Deploying Compounder Contract`);
  console.log(`Deployed at: ${compounder.address}`);
};

export default func;
func.tags = ["Compounder"];
