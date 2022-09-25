import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PLPStaking = await ethers.getContractFactory("PLPStaking", deployer);
  const plpStaking = await upgrades.deployProxy(PLPStaking, []);
  await plpStaking.deployed();
  console.log(`Deploying PLPStaking Contract`);
  console.log(`Deployed at: ${plpStaking.address}`);

  config.Staking.PLPStaking.address = plpStaking.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    plpStaking.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "PLPStaking",
  });
};

export default func;
func.tags = ["PLPStaking"];
