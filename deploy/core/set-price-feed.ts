import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolOracle__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const ORACLE = config.Pools.PLP.oracle;
const TOKENS = [
  config.Tokens.WMATIC, // WMATIC
  config.Tokens.WETH, // WETH
  config.Tokens.WBTC, // WBTC
  config.Tokens.USDC, // USDC
  config.Tokens.USDT, // USDT
];
const FEED_INFOS = [
  {
    priceFeed: "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0", // WMATIC
    decimals: 8,
    spreadBps: 0,
    isStrictStable: false,
  },
  {
    priceFeed: "0xF9680D99D6C9589e2a93a78A04A279e509205945", // WETH
    decimals: 8,
    spreadBps: 0,
    isStrictStable: false,
  },
  {
    priceFeed: "0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6", // WBTC
    decimals: 8,
    spreadBps: 0,
    isStrictStable: false,
  },
  {
    priceFeed: "0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7", // USDC
    decimals: 8,
    spreadBps: 0,
    isStrictStable: true,
  },
  {
    priceFeed: "0x0A6513e40db6EB1b165753AD52E80663aeA50545", // USDT
    decimals: 8,
    spreadBps: 0,
    isStrictStable: true,
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const oracle = PoolOracle__factory.connect(ORACLE, deployer);

  console.log("> Setting price feeds");
  const tx = await oracle.setPriceFeed(TOKENS, FEED_INFOS, {
    ...(await eip1559rapidGas()),
    gasLimit: 10000000,
  });
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Done setting price feeds`);
};

export default func;
func.tags = ["SetPriceFeed"];
