import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const PLP_TOKEN = "0xc88322Ec9526A7A98B7F58ff773b3B003C91ce71";
const POOL_CONFIG = "0x046E067104249e031339a659BC2BA37B460F77db";
const POOL_MATH = "0x28706a8A160b7C5f547997bC9f8672059FD3BF5B";
const POOL_ORACLE = "0x7d259B6a09aad1d94f49fB1cbEB825C4E8854bbc";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Pool = await ethers.getContractFactory("Pool", deployer);
  const pool = await upgrades.deployProxy(Pool, [
    PLP_TOKEN,
    POOL_CONFIG,
    POOL_MATH,
    POOL_ORACLE,
  ]);
  pool.deployed();
  console.log(`Deploying Pool Contract`);
  console.log(`Deployed at: ${pool.address}`);
};

export default func;
func.tags = ["Pool"];
