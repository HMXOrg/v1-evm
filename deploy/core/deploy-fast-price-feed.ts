import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const priceDuration = 300;
const maxPriceUpdateDelay = 3600;
const minBlockInterval = 1;
const maxDeviationBasisPoints = 1000;
const tokenManager = "0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a";
const positionRouter = config.Pools.PLP.marketOrderbook;
const orderbook = config.Pools.PLP.orderbook;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying FastPriceFeed Contract`);
  const FastPriceFeed = await ethers.getContractFactory(
    "FastPriceFeed",
    deployer
  );
  const fastPriceFeed = await upgrades.deployProxy(FastPriceFeed, [
    priceDuration,
    maxPriceUpdateDelay,
    minBlockInterval,
    maxDeviationBasisPoints,
    tokenManager,
    positionRouter,
    orderbook,
  ]);
  console.log(`> ⛓ Tx submitted: ${fastPriceFeed.deployTransaction.hash}`);
  await fastPriceFeed.deployTransaction.wait(3);
  console.log(`> Deployed at: ${fastPriceFeed.address}`);

  config.Pools.PLP.fastPriceFeed = fastPriceFeed.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    fastPriceFeed.address
  );

  console.log(`> Verifying contract on Tenderly...`);
  await tenderly.verify({
    address: implAddress,
    name: "FastPriceFeed",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["FastPriceFeed"];
