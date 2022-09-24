import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const roundDepth = 3;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolOracle = await ethers.getContractFactory("PoolOracle", deployer);
  const poolOracle = await upgrades.deployProxy(PoolOracle, [roundDepth]);
  await poolOracle.deployed();
  console.log(`Deploying PoolOracle Contract`);
  console.log(`Deployed at: ${poolOracle.address}`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    poolOracle.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "PoolOracle",
  });

  config.Pools.PLP.oracle = poolOracle.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["PoolOracle"];
