import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Orderbook = await ethers.getContractFactory(
    "RewardDistributor",
    deployer
  );
  const newOrderbookImp = await upgrades.prepareUpgrade(
    config.Staking.RewardDistributor.address,
    Orderbook
  );
  console.log(`> New Orderbook Implementation address: ${newOrderbookImp}`);
  await upgrades.upgradeProxy(
    config.Staking.RewardDistributor.address,
    Orderbook
  );

  const implAddress = await getImplementationAddress(
    ethers.provider,
    config.Staking.RewardDistributor.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "RewardDistributor",
  });
};

export default func;
func.tags = ["UpgradeRewardDistributor"];
