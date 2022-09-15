import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AdminFacetInterface__factory,
  PoolConfig__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

// Mainnet
const TOKENS = [
  config.Tokens.WMATIC, // WMATIC
  config.Tokens.WETH, // WETH
  config.Tokens.WBTC, // WBTC
  config.Tokens.DAI, // DAI
  config.Tokens.USDC, // USDC
  config.Tokens.USDT, // USDT
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
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );
  const tx = await pool.setTokenConfigs(TOKENS, TOKEN_CONFIGS);
  const txReceipt = await tx.wait();
  console.log(`Execute  setTokenConfigs`);
};

export default func;
func.tags = ["SetTokenConfigs"];
