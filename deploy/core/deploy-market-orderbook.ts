import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const minExecutionFee = ethers.utils.parseEther("0.2");
const minPurchaseTokenAmountUsd = ethers.utils.parseUnits("10", 30);

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying MarketOrderbook Contract`);
  const Orderbook = await ethers.getContractFactory("Orderbook", deployer);
  const orderbook = await upgrades.deployProxy(Orderbook, [
    config.Pools.PLP.poolDiamond,
    config.Pools.PLP.oracle,
    config.Tokens.WMATIC,
    minExecutionFee,
    minPurchaseTokenAmountUsd,
  ]);
  console.log(`> ⛓ Tx submitted: ${orderbook.deployTransaction.hash}`);
  console.log(`> Waiting tx to be mined...`);
  await orderbook.deployTransaction.wait(3);
  console.log(`> Tx mined!`);
  console.log(`> Deployed at: ${orderbook.address}`);

  config.Pools.PLP.orderbook = orderbook.address;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly...`);
  const implAddress = await getImplementationAddress(
    ethers.provider,
    orderbook.address
  );
  await tenderly.verify({
    address: implAddress,
    name: "Orderbook",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["Orderbook"];
