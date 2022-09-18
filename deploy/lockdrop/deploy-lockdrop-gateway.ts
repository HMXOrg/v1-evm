import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

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

  const implAddress = await getImplementationAddress(
    ethers.provider,
    lockdropGateway.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "LockdropGateway",
  });

  config.Lockdrop.gateway = lockdropGateway.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["LockdropGateway"];
