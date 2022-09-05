import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolConfig__factory } from "../../typechain";

const CONFIG = "0x880676cfcB5895a1B3fA65AD6E5cfc335316901c";
const TOKENS = [
  "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270", // WMATIC
  "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619", // WETH
  "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6", // WBTC
  "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", // DAI
  "0x2791bca1f2de4661ed88a30c99a7a9449aa84174", // USDC
  "0xc2132d05d31c914a87c6611c10748aeb04b58e8f", // USDT
];
const TOKEN_CONFIGS = [
  {
    accept: true,
    isStable: false,
    isShortable: true,
    decimals: 18,
    weight: 10000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
  {
    accept: true,
    isStable: false,
    isShortable: true,
    decimals: 18,
    weight: 10000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
  {
    accept: true,
    isStable: false,
    isShortable: true,
    decimals: 8,
    weight: 10000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
  {
    accept: true,
    isStable: true,
    isShortable: false,
    decimals: 18,
    weight: 10000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
  {
    accept: true,
    isStable: true,
    isShortable: false,
    decimals: 6,
    weight: 10000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
  {
    accept: true,
    isStable: true,
    isShortable: false,
    decimals: 6,
    weight: 10000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const config = PoolConfig__factory.connect(CONFIG, deployer);
  const tx = await config.setTokenConfigs(TOKENS, TOKEN_CONFIGS);
  const txReceipt = await tx.wait();
  console.log(`Execute  setTokenConfigs`);
};

export default func;
func.tags = ["SetTokenConfigs"];
