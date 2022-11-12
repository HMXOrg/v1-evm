import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`Deploying PoolDiamond Contract`);
  const PoolDiamond = await ethers.getContractFactory("PoolDiamond", deployer);
  const poolDiamond = await PoolDiamond.deploy(
    config.Pools.PLP.facets.diamondCut,
    config.Tokens.PLP,
    config.Pools.PLP.oracle
  );
  await poolDiamond.deployTransaction.wait(3);
  console.log(`Deployed at: ${poolDiamond.address}`);

  config.Pools.PLP.poolDiamond = poolDiamond.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: poolDiamond.address,
    name: "PoolDiamond",
  });
};

export default func;
func.tags = ["PoolDiamond"];
