import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const PoolDiamond = await ethers.getContractFactory("PoolDiamond", deployer);
  const poolDiamond = await PoolDiamond.deploy(
    config.Pools.PLP.facets.diamondCut,
    config.Tokens.PLP,
    config.Pools.PLP.oracle
  );
  poolDiamond.deployed();
  console.log(`Deploying PoolDiamond Contract`);
  console.log(`Deployed at: ${poolDiamond.address}`);
};

export default func;
func.tags = ["PoolDiamond"];
