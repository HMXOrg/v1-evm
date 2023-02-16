import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { MEVAegis__factory, Ownable__factory } from "../../typechain";
import { Transaction, queueTransaction } from "../utils/timelock";
import { writeJson } from "../utils/file";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const TITLE = "upgrade_mev_aegis";
  const EXACT_ETA = "1676457805";

  const timelockTransactions: Array<Transaction> = [];
  const deployer = (await ethers.getSigners())[0];
  const chainId = await deployer.getChainId();
  const MEVAegis = await ethers.getContractFactory("MEVAegis", deployer);
  const proxyAdmin = Ownable__factory.connect(config.ProxyAdmin, deployer);
  const newMEVAegisImp = await upgrades.prepareUpgrade(
    config.Pools.PLP.mevAegis,
    MEVAegis
  );

  console.log(`> New MEVAegis Implementation address: ${newMEVAegisImp}`);

  const owner = await proxyAdmin.owner();
  if (owner === config.Timelock) {
    timelockTransactions.push(
      await queueTransaction(
        chainId,
        `> Queue tx to upgrade ${config.Pools.PLP.mevAegis}`,
        config.ProxyAdmin,
        "0",
        "upgrade(address,address)",
        ["address", "address"],
        [config.Pools.PLP.mevAegis, newMEVAegisImp],
        EXACT_ETA
      )
    );

    const timestamp = Math.floor(Date.now() / 1000);
    writeJson(`${timestamp}_${TITLE}`, timelockTransactions);
  } else {
    const upgradeTx = await upgrades.upgradeProxy(
      config.Pools.PLP.mevAegis,
      MEVAegis
    );
    console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await upgradeTx.deployTransaction.wait(3);
    console.log(`> Tx is mined!`);
  }

  await tenderly.verify({
    address: newMEVAegisImp.toString(),
    name: "MEVAegis",
  });
};

export default func;
func.tags = ["UpgradeMEVAegis"];
