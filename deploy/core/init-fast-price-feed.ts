import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FastPriceFeed__factory, PoolOracle__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const minAuthorizations = 1;
const signers = ["0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a"];
const updaters = ["0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a"];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const fastPriceFeed = FastPriceFeed__factory.connect(
    config.Pools.PLP.fastPriceFeed,
    deployer
  );

  console.log("> Init FastPriceFeed");
  const tx = await fastPriceFeed.init(
    minAuthorizations,
    signers,
    updaters,
    await eip1559rapidGas()
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["InitFastPriceFeed"];
