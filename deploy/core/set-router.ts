import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const PoolRouter = config.PoolRouter;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );
  const tx = await pool.setRouter(PoolRouter);
  const txReceipt = await tx.wait();
  console.log(`Execute  setRouter`);
};

export default func;
func.tags = ["SetRouter"];
