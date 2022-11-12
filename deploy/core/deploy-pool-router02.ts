import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const WNATIVE = config.Tokens.WMATIC;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolRouter = await ethers.getContractFactory("PoolRouter02", deployer);

  console.log(`> Deploying PoolRouter02 Contract`);
  const poolRouter = await PoolRouter.deploy(
    WNATIVE,
    config.Staking.PLPStaking.address,
    config.Pools.PLP.poolDiamond,
    await eip1559rapidGas()
  );
  console.log(`> ⛓ Tx summited: ${poolRouter.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await poolRouter.deployTransaction.wait(3);
  console.log(`> Tx mined!`);
  console.log(`> ✅ Deployed at: ${poolRouter.address}`);

  config.PoolRouter = poolRouter.address;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly`);
  await tenderly.verify({
    address: poolRouter.address,
    name: "PoolRouter02",
  });
  console.log(`> ✅ Verified on Tenderly`);
};

export default func;
func.tags = ["PoolRouter02"];
