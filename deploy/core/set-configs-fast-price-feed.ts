import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FastPriceFeed__factory, PoolOracle__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const tokens = [config.Tokens.WBTC, config.Tokens.WETH, config.Tokens.WMATIC];
const tokenPrecisions = [1000, 1000, 1000];
const minAuthorizations = 1;
const priceDataInterval = 60;
const maxCumulativeDeltaDiffs = [1000000, 1000000, 1000000];
const maxTimeDeviation = 3600;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const fastPriceFeed = FastPriceFeed__factory.connect(
    config.Pools.PLP.fastPriceFeed,
    deployer
  );

  console.log("> Set Configs for FastPriceFeed");
  const tx = await fastPriceFeed.setConfigs(
    tokens,
    tokenPrecisions,
    minAuthorizations,
    priceDataInterval,
    maxCumulativeDeltaDiffs,
    maxTimeDeviation
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetConfigsFastPriceFeed"];
