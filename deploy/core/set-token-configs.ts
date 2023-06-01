import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const TOKEN_CONFIGS = [
  // {
  //   token: config.Tokens.WMATIC,
  //   accept: true,
  //   isStable: false,
  //   isShortable: true,
  //   decimals: 18,
  //   weight: 500,
  //   minProfitBps: 0,
  //   usdDebtCeiling: ethers.utils.parseEther("0"),
  //   shortCeiling: ethers.utils.parseUnits("0", 30),
  //   bufferLiquidity: ethers.utils.parseUnits("0", 18),
  //   openInterestLongCeiling: ethers.utils.parseUnits("0", 18),
  // },
  // {
  //   token: config.Tokens.WETH,
  //   accept: true,
  //   isStable: false,
  //   isShortable: true,
  //   decimals: 18,
  //   weight: 2500,
  //   minProfitBps: 0,
  //   usdDebtCeiling: ethers.utils.parseEther("0"),
  //   shortCeiling: ethers.utils.parseUnits("0", 30),
  //   bufferLiquidity: ethers.utils.parseUnits("0", 18),
  //   openInterestLongCeiling: ethers.utils.parseUnits("0", 18),
  // },
  // {
  //   token: config.Tokens.WBTC,
  //   accept: true,
  //   isStable: false,
  //   isShortable: true,
  //   decimals: 8,
  //   weight: 2000,
  //   minProfitBps: 0,
  //   usdDebtCeiling: ethers.utils.parseEther("0"),
  //   shortCeiling: ethers.utils.parseUnits("0", 30),
  //   bufferLiquidity: ethers.utils.parseUnits("0", 8),
  //   openInterestLongCeiling: ethers.utils.parseUnits("0", 8),
  // },
  {
    token: config.Tokens.USDC,
    accept: true,
    isStable: true,
    isShortable: false,
    decimals: 6,
    weight: 2500,
    minProfitBps: 0,
    usdDebtCeiling: ethers.utils.parseEther("0"),
    shortCeiling: 0,
    bufferLiquidity: ethers.utils.parseUnits("0", 6),
    openInterestLongCeiling: 0,
  },
  {
    token: config.Tokens.USDT,
    accept: true,
    isStable: true,
    isShortable: false,
    decimals: 6,
    weight: 2500,
    minProfitBps: 0,
    usdDebtCeiling: ethers.utils.parseEther("0"),
    shortCeiling: 0,
    bufferLiquidity: ethers.utils.parseUnits("0", 6),
    openInterestLongCeiling: 0,
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  console.log("> Setting token configs");
  const tx = await pool.setTokenConfigs(
    TOKEN_CONFIGS.map((each) => each.token),
    TOKEN_CONFIGS,
    await eip1559rapidGas()
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Token configs set`);
};

export default func;
func.tags = ["SetTokenConfigs"];
