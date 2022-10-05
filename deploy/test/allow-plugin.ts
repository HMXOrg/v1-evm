import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AccessControlFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AccessControlFacetInterface__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );
  const tx = await pool.allowPlugin(config.Pools.PLP.orderbook)
  const txReceipt = await tx.wait();
  console.log(`Execute allowPlugin`);
  console.log(`Plugin: ${config.Pools.PLP.orderbook}`);
};

export default func;
func.tags = ["AllowPlugin"];
