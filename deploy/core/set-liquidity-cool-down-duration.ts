import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolConfig__factory } from "../../typechain";

const CONFIG = "0x202310a1e88812d35B559f089eafa7E2Ae172286";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const config = PoolConfig__factory.connect(CONFIG, deployer);
  const tx = await config.setLiquidityCoolDownDuration(0);
  const txReceipt = await tx.wait();
  console.log(`Execute  setLiquidityCoolDownDuration`);
};

export default func;
func.tags = ["SetLiquidityCoolDownDuration"];