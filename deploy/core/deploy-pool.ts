import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const PLP_TOKEN = "0xc88322Ec9526A7A98B7F58ff773b3B003C91ce71";
const POOL_CONFIG = "0x880676cfcB5895a1B3fA65AD6E5cfc335316901c";
const POOL_MATH = "0xb758A54cE1eD2B618001005Eb82DD79DB002624C";
const POOL_ORACLE = "0x9375e7eE3a50E82D5C5CB34cf6AB2d8AdE4B469f";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Pool = await ethers.getContractFactory("Pool", deployer);
  // const pool = await upgrades.deployProxy(Pool, [
  //   PLP_TOKEN,
  //   POOL_CONFIG,
  //   POOL_MATH,
  //   POOL_ORACLE,
  // ]);

  const pool = await Pool.deploy(
    PLP_TOKEN,
    POOL_CONFIG,
    POOL_MATH,
    POOL_ORACLE
  );
  pool.deployed();
  console.log(`Deploying Pool Contract`);
  console.log(`Deployed at: ${pool.address}`);
};

export default func;
func.tags = ["Pool"];
