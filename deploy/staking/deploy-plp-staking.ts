import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying PLPStaking Contract`);
  const PLPStaking = await ethers.getContractFactory("PLPStaking", deployer);
  const plpStaking = await upgrades.deployProxy(PLPStaking, []);
  console.log(`> ⛓ Tx submitted: ${plpStaking.deployTransaction.hash}`);
  await plpStaking.deployTransaction.wait(3);
  console.log(`> Deployed at: ${plpStaking.address}`);

  config.Staking.PLPStaking.address = plpStaking.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    plpStaking.address
  );

  console.log(`> Verifying contract on Tenderly...`);
  await tenderly.verify({
    address: implAddress,
    name: "PLPStaking",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["PLPStaking"];
