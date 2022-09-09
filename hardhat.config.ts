import { config as dotEnvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
dotEnvConfig();

import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    polygon: {
      url: process.env.POLYGON_MAINNET_RPC,
      accounts:
        process.env.POLYGON_MAINNET_PRIVATE_KEY !== undefined
          ? [process.env.POLYGON_MAINNET_PRIVATE_KEY]
          : [],
    },
  },
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1,
      },
    },
  },
  paths: {
    sources: "./src",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  typechain: {
    outDir: "./typechain",
    target: "ethers-v5",
  },
  mocha: {
    timeout: 100000,
  },
};

export default config;
