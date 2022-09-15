import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const ESP88 = config.Tokens.esP88;
const P88 = config.Tokens.P88;
const VESTED_ADDRESS = "0x000000000000000000000000000000000000dead";
const UNUSED_ADDRESS = "0x6629ec35c8aa279ba45dbfb575c728d3812ae31a";

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
