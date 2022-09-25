import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

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

  config.Vester = vester.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    vester.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "Vester",
  });
};

export default func;
func.tags = ["Vester"];
