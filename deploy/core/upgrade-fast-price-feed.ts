import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const FastPriceFeed = await ethers.getContractFactory(
    "FastPriceFeed",
    deployer
  );
  const newFastPriceFeedImp = await upgrades.prepareUpgrade(
    config.Pools.PLP.fastPriceFeed,
    FastPriceFeed
  );
  console.log(
    `> New FastPriceFeed Implementation address: ${newFastPriceFeedImp}`
  );
  await upgrades.upgradeProxy(config.Pools.PLP.fastPriceFeed, FastPriceFeed);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    config.Pools.PLP.fastPriceFeed
  );

  await tenderly.verify({
    address: implAddress,
    name: "FastPriceFeed",
  });
};

export default func;
func.tags = ["UpgradeFastPriceFeed"];
