import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { DragonPoint__factory } from "../../typechain";

const TOKEN_ADDRESS = "0x41E01292699513Fb5b202f97b98B361BF39E7c5F";
const TRANSFERRER_ADDRESS = "0x5c0f9425ab82ad53b009f02b2c2857544e74cc86";

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
