import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const DRAGON_POINT = ethers.constants.AddressZero;
const DESTINATION_COMPUND_POOL = ethers.constants.AddressZero;
const TOKENS = [config.Tokens.USDC];
const IS_COMPOUNDABLE_TOKENS = [false];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Compounder = await ethers.getContractFactory("Compounder", deployer);
  const compounder = await upgrades.deployProxy(Compounder, [
    DRAGON_POINT,
    DESTINATION_COMPUND_POOL,
    TOKENS,
    IS_COMPOUNDABLE_TOKENS,
  ]);
  await compounder.deployed();
  console.log(`Deploying Compounder Contract`);
  console.log(`Deployed at: ${compounder.address}`);

  config.Staking.Compounder = compounder.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    compounder.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "Compounder",
  });
};

export default func;
func.tags = ["Compounder"];
