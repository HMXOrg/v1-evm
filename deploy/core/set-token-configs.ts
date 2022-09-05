import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolConfig__factory } from "../../typechain";

const CONFIG = "0x3760f978AcE668209E415c0576a4d4f064850226";
const TOKENS = [
  "0x9c3c9283d3e44854697cd22d3faa240cfb032889", // WMATIC
  "0x2859751c033E64b1050f5E9642C4848293D3caE1", // WETH
  "0xC4F51bc480154e5B270967C70B64b53d0C189079", // WBTC
  "0x7FeC31e5966C84E8A81C574a0504ff637E3CC569", // DAI
  "0xFc99D238c7A20895ba3756Ee04FD8BfD442c18fD", // USDC
  "0xF21405bA59E79762C306c83298dbD10a8A285f2F", // USDT
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
