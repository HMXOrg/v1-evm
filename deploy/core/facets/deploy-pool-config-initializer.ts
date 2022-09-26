import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolConfigInitializer = await ethers.getContractFactory(
    "PoolConfigInitializer",
    deployer
  );
  console.log(`Deploying PoolConfigInitializer Contract`);
  const poolConfigInitializer = await PoolConfigInitializer.deploy();
  await poolConfigInitializer.deployed();
  console.log(`Deployed at: ${poolConfigInitializer.address}`);

  config.Pools.PLP.facets.poolConfigInitializer = poolConfigInitializer.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: poolConfigInitializer.address,
    name: "PoolConfigInitializer",
  });
};

export default func;
func.tags = ["PoolConfigInitializer"];
