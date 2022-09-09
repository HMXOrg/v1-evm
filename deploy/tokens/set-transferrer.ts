import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { DragonPoint__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.DragonPoint;
const TRANSFERRER_ADDRESS = "0xb366c92fF7CCE8d87De62DE52F19993Da7CB2024";

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
