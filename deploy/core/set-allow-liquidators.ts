import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const LIQUIDATORS = ["0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a"];

const PoolRouter = config.PoolRouter;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );
  const tx = await pool.setAllowLiquidators(LIQUIDATORS, true);
  const txReceipt = await tx.wait();
  console.log(`Execute setAllowLiquidators`);
};

export default func;
func.tags = ["SetAllowLiquidators"];
