import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const ESP88 = "0xB0897464c0b0C400052fD292Db28A2942df1e705";
const P88 = "0xB0897464c0b0C400052fD292Db28A2942df1e705";
const VESTED_ADDRESS = "0x0000000000000000000000000000000000000000";
const UNUSED_ADDRESS = "0x000000000000000000000000000000000000dead";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Vester = await ethers.getContractFactory("Vester", deployer);
  const vester = await upgrades.deployProxy(Vester, [
    ESP88,
    P88,
    VESTED_ADDRESS,
    UNUSED_ADDRESS,
  ]);
  await vester.deployed();
  console.log(`Deploying Vester Contract`);
  console.log(`Deployed at: ${vester.address}`);
};

export default func;
func.tags = ["Vester"];
