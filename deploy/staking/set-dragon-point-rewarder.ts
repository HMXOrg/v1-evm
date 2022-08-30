import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { BaseStaking__factory, DragonStaking__factory } from "../../typechain";

const STAKING_CONTRACT_ADDRESS = "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d";
const DRAGON_POINT_REWARDER = "0xfc51C8c673C27e1b3D89688ef46D706A77CA28DB";

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
