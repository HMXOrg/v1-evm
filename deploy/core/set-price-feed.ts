import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolOracle__factory } from "../../typechain";

const ORACLE = "0x832a59773e7a0896cF348C5EA72670D7CD37572D";
const TOKENS = [
  "0x9c3c9283d3e44854697cd22d3faa240cfb032889", // WMATIC
  "0x2859751c033E64b1050f5E9642C4848293D3caE1", // WETH
  "0xC4F51bc480154e5B270967C70B64b53d0C189079", // WBTC
  "0x7FeC31e5966C84E8A81C574a0504ff637E3CC569", // DAI
  "0xFc99D238c7A20895ba3756Ee04FD8BfD442c18fD", // USDC
  "0xF21405bA59E79762C306c83298dbD10a8A285f2F", // USDT
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
