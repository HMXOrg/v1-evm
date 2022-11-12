import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const LIQUIDATORS = ["0x437E5c6207C96D1bA51b11D59155347655912aaE"];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  console.log(`> Allow liquidators...`);
  const tx = await pool.setAllowLiquidators(
    LIQUIDATORS,
    true,
    await eip1559rapidGas()
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> Tx mined!`);

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetAllowLiquidators"];
