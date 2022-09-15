import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const plpToken = config.Tokens.PLP;
const plpStaking = config.Staking.PLPStaking.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LockdropGateway = await ethers.getContractFactory(
    "LockdropGateway",
    deployer
  );
  const lockdropGateway = await upgrades.deployProxy(LockdropGateway, [
    plpToken,
    plpStaking,
  ]);
  await lockdropGateway.deployed();
  console.log(`Deploying LockdropGateway Contract`);
  console.log(`Deployed at: ${lockdropGateway.address}`);
};

export default func;
func.tags = ["LockdropGateway"];
