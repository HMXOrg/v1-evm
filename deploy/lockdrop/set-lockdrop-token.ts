import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { LockdropGateway__factory, PoolConfig__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

enum TokenType {
  UninitializedToken,
  BaseToken,
  AToken, // Aave
  LpPairToken, // SushiSwap, QuickSwap
  CurveV3Token, // Curve Aave LP Token (only support 3 underlycoins)
  CurveV5Token, // ATriCrypto3 LP Token (only support 5 underlycoins)
}

const QUICKSWAP_ROUTER = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff";
const LOCKDROP_GATEWAY = config.Lockdrop.gateway;
const TOKEN_LIST = [
  {
    token: "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270", // WMATIC
    type: TokenType.BaseToken,
    lockdrop: "0x6199752F181dC74fCf887F9F0f7B7B6Eb26D5A7B",
  },
  {
    token: "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619", // WETH
    type: TokenType.BaseToken,
    lockdrop: "0x69F493e47C2793AbA58AbC5c1aaaA1d6DB60b608",
  },
  {
    token: "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6", // WBTC
    type: TokenType.BaseToken,
    lockdrop: "0x66B7b19E1A8D2DdED0566ce386c9bCEB7F4177ec",
  },
  {
    token: "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", // DAI
    type: TokenType.BaseToken,
    lockdrop: "0xC44b8fb84B61AcEa1D46665999f4b0543AA1aF3B",
  },
  {
    token: "0x2791bca1f2de4661ed88a30c99a7a9449aa84174", // USDC
    type: TokenType.BaseToken,
    lockdrop: "0x176d0A1EBCBa7863a3AF7db989dedA867e587adf",
  },
  {
    token: "0xc2132d05d31c914a87c6611c10748aeb04b58e8f", // USDT
    type: TokenType.BaseToken,
    lockdrop: "0x563960B166266b2bbaaC4561491603101C9Fa676",
  },
  {
    token: "0x1a13F4Ca1d028320A707D99520AbFefca3998b7F", // aUSDC
    type: TokenType.AToken,
  },
  {
    token: "0x60D55F02A771d515e077c9C2403a1ef324885CeC", // aUSDT
    type: TokenType.AToken,
  },
  {
    token: "0x27F8D03b3a2196956ED754baDc28D73be8830A6e", // aDAI
    type: TokenType.AToken,
  },
  {
    token: "0x5c2ed810328349100A66B82b78a1791B101C9D61", // aWBTC
    type: TokenType.AToken,
  },
  {
    token: "0x28424507fefb6f7f8E9D3860F56504E4e5f5f390", // aWETH
    type: TokenType.AToken,
  },
  {
    token: "0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4", // aMATIC
    type: TokenType.AToken,
  },
  {
    token: "0x853ee4b2a13f8a742d64c8f088be7ba2131f670d", // Quickswap ETH-USDC LP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0xdc9232e2df177d7a12fdff6ecbab114e2231198d", // Quickswap ETH-WBTC LP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0xf6422b997c7f54d1c6a6e103bcb1499eea0a7046", // Quickswap ETH-USDT LP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0x4a35582a710e1f4b2030a3f826da20bfb6703c09", // Quickswap ETH-DAI LP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0x2cf7252e74036d1da831d11089d326296e64a728", // Quickswap USDC-USDT LP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0xf6a637525402643b0654a54bead2cb9a83c8b498", // Quickswap USDC-WBTC LP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0xadbf1854e5883eb8aa7baf50705338739e558e5b", // Quickswap MATIC-ETH LP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0x6e7a5fafcec6bb1e78bae2a1f0b612012bf14827", // Quickswap MATIC-USDCLP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0x604229c960e5cacf2aaeac8be68ac07ba9df81c3", // Quickswap MATIC-USDT LP
    type: TokenType.LpPairToken,
    router: QUICKSWAP_ROUTER,
  },
  {
    token: "0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171", // aave USD
    type: TokenType.CurveV3Token,
  },
  {
    token: "0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3", // atricrypto3
    type: TokenType.CurveV5Token,
    zap: "0x1d8b86e3D88cDb2d34688e87E72F388Cb541B7C8",
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const lockdropGateway = LockdropGateway__factory.connect(
    LOCKDROP_GATEWAY,
    deployer
  );
  for (let i = 0; i < TOKEN_LIST.length; i++) {
    const tokenConfig = TOKEN_LIST[i];
    if (tokenConfig.type === TokenType.BaseToken) {
      await (
        await lockdropGateway.setBaseTokenLockdropInfo(
          tokenConfig.token,
          tokenConfig.lockdrop!
        )
      ).wait();
      console.log(`Execute setBaseTokenLockdropInfo`);
    } else if (tokenConfig.type === TokenType.AToken) {
      await (
        await lockdropGateway.setATokenLockdropInfo(tokenConfig.token)
      ).wait();
      console.log(`Execute setATokenLockdropInfo`);
    } else if (tokenConfig.type === TokenType.LpPairToken) {
      await (
        await lockdropGateway.setLpPairTokenLockdropInfo(
          tokenConfig.token,
          tokenConfig.router!
        )
      ).wait();
      console.log(`Execute setLpPairTokenLockdropInfo`);
    } else if (tokenConfig.type === TokenType.CurveV3Token) {
      await (
        await lockdropGateway.setCurveV3TokenLockdropInfo(tokenConfig.token)
      ).wait();
      console.log(`Execute setCurveV3TokenLockdropInfo`);
    } else if (tokenConfig.type === TokenType.CurveV5Token) {
      await (
        await lockdropGateway.setCurveV5TokenLockdropInfo(
          tokenConfig.token,
          tokenConfig.zap!,
          5
        )
      ).wait();
      console.log(`Execute setCurveV5TokenLockdropInfo`);
    }
  }
};

export default func;
func.tags = ["SetLockdropToken"];
