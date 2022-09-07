import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolConfig__factory } from "../../typechain";

const CONFIG = "0x880676cfcB5895a1B3fA65AD6E5cfc335316901c";
const PoolRouter = "0xEA37E047fAf6867Ef38bbB601A25162E5743c6D3";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const config = PoolConfig__factory.connect(CONFIG, deployer);
  const tx = await config.setRouter(PoolRouter);
  const txReceipt = await tx.wait();
  console.log(`Execute  setRouter`);
};

export default func;
func.tags = ["SetRouter"];
