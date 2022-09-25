import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AdminFacetInterface__factory,
  PoolConfig__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_CONFIGS = [
  {
    token: config.Tokens.WMATIC,
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
    token: config.Tokens.WETH,
    accept: true,
    isStable: false,
    isShortable: true,
    decimals: 18,
    weight: 20000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
  {
    token: config.Tokens.WBTC,
    accept: true,
    isStable: false,
    isShortable: true,
    decimals: 8,
    weight: 20000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
  {
    token: config.Tokens.DAI,
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
    token: config.Tokens.USDC,
    accept: true,
    isStable: true,
    isShortable: false,
    decimals: 6,
    weight: 30000,
    minProfitBps: 75,
    usdDebtCeiling: 0,
    shortCeiling: 0,
    bufferLiquidity: 0,
  },
  {
    token: config.Tokens.USDT,
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
  const tx = await pool.setTokenConfigs(
    TOKEN_CONFIGS.map((each) => each.token),
    TOKEN_CONFIGS
  );
  const txReceipt = await tx.wait();
  console.log(`Execute  setTokenConfigs`);
};

export default func;
func.tags = ["SetTokenConfigs"];
