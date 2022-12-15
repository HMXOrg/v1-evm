import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Orderbook = await ethers.getContractFactory("Orderbook", deployer);
  const newOrderbookImp = await upgrades.prepareUpgrade(
    config.Pools.PLP.orderbook,
    Orderbook
  );
  console.log(`> New Orderbook Implementation address: ${newOrderbookImp}`);
  const tx = await upgrades.upgradeProxy(config.Pools.PLP.orderbook, Orderbook);
  await tx.deployed();
  console.log(`Upgrade successful!`);

  await tenderly.verify({
    address: newOrderbookImp.toString(),
    name: "Orderbook",
  });
};

export default func;
func.tags = ["UpgradeOrderbook"];
