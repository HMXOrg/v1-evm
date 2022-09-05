import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolOracle__factory } from "../../typechain";

const ORACLE = "0x9375e7eE3a50E82D5C5CB34cf6AB2d8AdE4B469f";
const TOKENS = [
  "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270", // WMATIC
  "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619", // WETH
  "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6", // WBTC
  "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", // DAI
  "0x2791bca1f2de4661ed88a30c99a7a9449aa84174", // USDC
  "0xc2132d05d31c914a87c6611c10748aeb04b58e8f", // USDT
];
const FEED_INFOS = [
  {
    priceFeed: "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0", // WMATIC
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0xF9680D99D6C9589e2a93a78A04A279e509205945", // WETH
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6", // WBTC
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D", // DAI
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7", // USDC
    decimals: 8,
    spreadBps: 10,
    isStrictStable: false,
  },
  {
    priceFeed: "0x0A6513e40db6EB1b165753AD52E80663aeA50545", // USDT
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
