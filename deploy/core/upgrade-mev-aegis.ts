import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const MEVAegis = await ethers.getContractFactory("MEVAegis", deployer);
  const newMEVAegisImp = await upgrades.prepareUpgrade(
    config.Pools.PLP.mevAegis,
    MEVAegis
  );

  console.log(`> New MEVAegis Implementation address: ${newMEVAegisImp}`);
  const upgradeTx = await upgrades.upgradeProxy(
    config.Pools.PLP.mevAegis,
    MEVAegis
  );
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await upgradeTx.deployTransaction.wait(3);
  console.log(`> Tx is mined!`);

  await tenderly.verify({
    address: newMEVAegisImp.toString(),
    name: "MEVAegis",
  });
};

export default func;
func.tags = ["UpgradeMEVAegis"];
