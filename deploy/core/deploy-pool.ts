import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const PLP_TOKEN = "0xBb5e11926b8040ccFa67045aF552F47C735CfF87";
const POOL_CONFIG = "0xD941773cfaC0EaE3e2d790EaB7cCfADe0Ab87e23";
const POOL_MATH = "0x66C329DBFAa943E44Eb0402012229465550b35E0";
const POOL_ORACLE = "0xA9AA532ae9C3bd2Cf68A990e5478764C60f959D1";

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
