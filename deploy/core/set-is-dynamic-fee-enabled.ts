import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolConfig__factory } from "../../typechain";

const CONFIG = "0x3760f978AcE668209E415c0576a4d4f064850226";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const config = PoolConfig__factory.connect(CONFIG, deployer);
  const tx = await config.setIsDynamicFeeEnable(true);
  const txReceipt = await tx.wait();
  console.log(`Execute  setIsDynamicFeeEnable`);
};

export default func;
func.tags = ["SetIsDynamicFeeEnable"];
