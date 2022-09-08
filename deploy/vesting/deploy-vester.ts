import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const ESP88 = "0xEB27B05178515c7E6E51dEE159c8487A011ac030";
const P88 = "0xB853c09b6d03098b841300daD57701ABcFA80228";
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
