import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { DragonStaking__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const STAKING_CONTRACT_ADDRESS = config.Staking.DragonStaking.address;
const DRAGON_POINT_REWARDER = config.Staking.DragonStaking.rewarders.find(
  (each: any) => each.name === "Dragon Staking Dragon Point Emission"
).address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const stakingContract = DragonStaking__factory.connect(
    STAKING_CONTRACT_ADDRESS,
    deployer
  );
  const tx = await stakingContract.setDragonPointRewarder(
    DRAGON_POINT_REWARDER
  );
  const txReceipt = await tx.wait();
  console.log(`Execute  setDragonPointRewarder`);
  console.log(`Staking Contract: ${STAKING_CONTRACT_ADDRESS}`);
  console.log(`DragonPointRewarder: ${DRAGON_POINT_REWARDER}`);
};

export default func;
func.tags = ["SetDragonPointRewarder"];
