import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const delay = 60 * 60 * 24; // 1 day
const admin = "0x6a5D2BF8ba767f7763cd342Cb62C5076f9924872";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const Timelock = await ethers.getContractFactory("Timelock", deployer);
  console.log(`Deploying Timelock Contract`);
  const timelock = await Timelock.deploy(admin, delay, await eip1559rapidGas());
  console.log(`> ⛓ Tx submitted: ${timelock.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await timelock.deployTransaction.wait(3);
  console.log(`> Deployed at: ${timelock.address}`);

  config.Timelock = timelock.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: timelock.address,
    name: "Timelock",
  });
};

export default func;
func.tags = ["Timelock"];
