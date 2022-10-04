import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Orderbook = await ethers.getContractFactory("Orderbook", deployer);
  const orderbook = await upgrades.deployProxy(Orderbook, [
    config.Pools.PLP.poolDiamond,
    config.Pools.PLP.oracle,
    config.Tokens.WMATIC,
    ethers.utils.parseEther("0.01"),
    ethers.utils.parseUnits("10", 30),
  ]);
  await orderbook.deployed();
  console.log(`Deploying Orderbook Contract`);
  console.log(`Deployed at: ${orderbook.address}`);

  config.Pools.PLP.orderbook = orderbook.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    orderbook.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "Orderbook",
  });
};

export default func;
func.tags = ["Orderbook"];
