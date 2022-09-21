import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PerpTradeFacet__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = PerpTradeFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  await (
    await pool.liquidate(
      "0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a",
      0,
      config.Tokens.WBTC,
      config.Tokens.WBTC,
      true,
      deployer.address,
      { gasLimit: 10000000 }
    )
  ).wait();
  console.log(`Execute liquidate`);
};

export default func;
func.tags = ["LiquidatePosition"];
