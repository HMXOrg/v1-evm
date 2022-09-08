import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const DRAGON_POINT = "0x20E58fC5E1ee3C596fb3ebD6de6040e7800e82E6";
const DESTINATION_COMPUND_POOL = "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d";
const TOKENS = [
  "0xEB27B05178515c7E6E51dEE159c8487A011ac030",
  "0x20E58fC5E1ee3C596fb3ebD6de6040e7800e82E6",
];
const IS_COMPOUNDABLE_TOKENS = [true, true];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Compounder = await ethers.getContractFactory("Compounder", deployer);
  const compounder = await upgrades.deployProxy(Compounder, [
    DRAGON_POINT,
    DESTINATION_COMPUND_POOL,
    TOKENS,
    IS_COMPOUNDABLE_TOKENS,
  ]);
  await compounder.deployed();
  console.log(`Deploying Compounder Contract`);
  console.log(`Deployed at: ${compounder.address}`);
};

export default func;
func.tags = ["Compounder"];
