import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { DragonPoint__factory } from "../../typechain";

const TOKEN_ADDRESS = "0x20E58fC5E1ee3C596fb3ebD6de6040e7800e82E6";
const TRANSFERRER_ADDRESS = "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = DragonPoint__factory.connect(TOKEN_ADDRESS, deployer);
  const tx = await token.setTransferrer(TRANSFERRER_ADDRESS, true);
  const txReceipt = await tx.wait();
  console.log(`Execute  setTransferrer`);
  console.log(`Token: ${TOKEN_ADDRESS}`);
  console.log(`Minter: ${TRANSFERRER_ADDRESS}`);
};

export default func;
func.tags = ["SetTransferrer"];
