import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolOracle__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

// Testnet
const ORACLE = config.Pools.PLP.oracle;
const TOKENS = [
  config.Tokens.WMATIC, // WMATIC
  config.Tokens.WETH, // WETH
  config.Tokens.WBTC, // WBTC
  config.Tokens.DAI, // DAI
  config.Tokens.USDC, // USDC
  config.Tokens.USDT, // USDT
];
const FEED_INFOS = [
  {
    priceFeed: "0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada", // WMATIC
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A", // WETH
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0x007A22900a3B98143368Bd5906f8E17e9867581b", // WBTC
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046", // DAI
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0", // USDC
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0x92C09849638959196E976289418e5973CC96d645", // USDT
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const oracle = PoolOracle__factory.connect(ORACLE, deployer);
  const tx = await oracle.setPriceFeed(TOKENS, FEED_INFOS, {
    gasLimit: 10000000,
  });
  const txReceipt = await tx.wait();
  console.log(`Execute  setPriceFeed`);
};

export default func;
func.tags = ["SetPriceFeed"];
