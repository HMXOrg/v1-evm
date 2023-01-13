import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Orderbook = await ethers.getContractFactory(
    "MarketOrderbook",
    deployer
  );
  const newOrderbookImp = await upgrades.prepareUpgrade(
    config.Pools.PLP.marketOrderbook,
    Orderbook
  );
  console.log(
    `> New MarketOrderbook Implementation address: ${newOrderbookImp}`
  );
  const upgradeTx = await upgrades.upgradeProxy(
    config.Pools.PLP.marketOrderbook,
    Orderbook
  );
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await upgradeTx.deployTransaction.wait(3);
  console.log(`> Tx is mined!`);

  await tenderly.verify({
    address: newOrderbookImp.toString(),
    name: "MarketOrderbook",
  });
};

export default func;
func.tags = ["UpgradeMarketOrderbook"];
