import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();
const LIQUIDITY_COOLDOWN = 60 * 15; // 15 minutes

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PLP = await ethers.getContractFactory("PLP", deployer);
  const plp = await upgrades.deployProxy(PLP, [LIQUIDITY_COOLDOWN]);
  await plp.deployed();
  console.log(`Deploying PLP Token Contract`);
  console.log(`Deployed at: ${plp.address}`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    plp.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "PLP",
  });

  config.Tokens.PLP = plp.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["PLPToken"];
