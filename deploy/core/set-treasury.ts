import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TREASURY_ADDRESS = config.Staking.RewardDistributor.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );
  const tx = await pool.setTreasury(TREASURY_ADDRESS);
  const txReceipt = await tx.wait();
  console.log(`Execute setTreasury`);
};

export default func;
func.tags = ["SetTreasury"];
