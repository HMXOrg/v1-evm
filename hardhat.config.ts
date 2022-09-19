import { config as dotEnvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
dotEnvConfig();

import * as tdly from "@tenderly/hardhat-tenderly";
tdly.setup({ automaticVerifications: false });

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
    mumbai: {
      url: process.env.POLYGON_MUMBAI_RPC,
      accounts:
        process.env.POLYGON_MUMBAI_PRIVATE_KEY !== undefined
          ? [process.env.POLYGON_MUMBAI_PRIVATE_KEY]
          : [],
    },
    tenderly: {
      chainId: 137,
      url: "https://rpc.tenderly.co/fork/174d3639-ceef-4578-838d-5d6aecfb7ddd",
    },
  },
  solidity: {
    version: "0.8.17",
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
  tenderly: {
    project: process.env.TENDERLY_PROJECT_NAME!,
    username: process.env.TENDERLY_USERNAME!,
    privateVerification: true,
  },
};

export default config;
