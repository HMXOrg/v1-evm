import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolConfigInitializer = await ethers.getContractFactory(
    "PoolConfigInitializer02",
    deployer
  );

  console.log(`Deploying PoolConfigInitializer02 Contract`);
  const poolConfigInitializer = await PoolConfigInitializer.deploy();
  await poolConfigInitializer.deployTransaction.wait(3);
  console.log(`Deployed at: ${poolConfigInitializer.address}`);

  config.Pools.PLP.facets.poolConfigInitializer = poolConfigInitializer.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: poolConfigInitializer.address,
    name: "PoolConfigInitializer02",
  });
};

export default func;
func.tags = ["PoolConfigInitializer"];
