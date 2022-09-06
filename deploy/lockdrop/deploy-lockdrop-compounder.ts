import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const esp88Token = "0xEB27B05178515c7E6E51dEE159c8487A011ac030";
const dragonStaking = "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LockdropCompounder = await ethers.getContractFactory(
    "LockdropCompounder",
    deployer
  );
  const lockdropCompounder = await upgrades.deployProxy(LockdropCompounder, [
    esp88Token,
    dragonStaking,
  ]);
  await lockdropCompounder.deployed();
  console.log(`Deploying LockdropCompounder Contract`);
  console.log(`Deployed at: ${lockdropCompounder.address}`);
};

export default func;
func.tags = ["LockdropCompounder"];
