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

  console.log(`> Preparing to upgrade RewardDistributor`);
  const newOrderbookImpDeployTx = await upgrades.prepareUpgrade(
    config.Staking.RewardDistributor.address,
    Orderbook
  );
  console.log(`> Done`);

  console.log(
    `> New Orderbook Implementation address: ${newOrderbookImpDeployTx}`
  );
  const upgradeTx = await upgrades.upgradeProxy(
    config.Staking.RewardDistributor.address,
    Orderbook
  );
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await upgradeTx.deployTransaction.wait(3);
  console.log(`> Tx is mined!`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    config.Staking.RewardDistributor.address
  );

  console.log(`> Verify contract on Tenderly`);
  await tenderly.verify({
    address: implAddress,
    name: "RewardDistributor",
  });
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["UpgradeRewardDistributor"];
