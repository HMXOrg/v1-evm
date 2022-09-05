import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolConfig__factory } from "../../typechain";

const CONFIG = "0x880676cfcB5895a1B3fA65AD6E5cfc335316901c";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const config = PoolConfig__factory.connect(CONFIG, deployer);
  const tx = await config.setIsDynamicFeeEnable(true);
  const txReceipt = await tx.wait();
  console.log(`Execute  setIsDynamicFeeEnable`);
};

export default func;
func.tags = ["SetIsDynamicFeeEnable"];
