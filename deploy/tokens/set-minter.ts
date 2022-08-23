import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  BaseStaking__factory,
  MintableTokenInterface__factory,
} from "../../typechain";

const TOKEN_ADDRESS = "0x41E01292699513Fb5b202f97b98B361BF39E7c5F";
const MINTER_ADDRESS = "0x108d83658bD43C9e427C64238EF7d79912dbb2fA";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = MintableTokenInterface__factory.connect(
    TOKEN_ADDRESS,
    deployer
  );
  const tx = await token.setMinter(MINTER_ADDRESS, true);
  const txReceipt = await tx.wait();
  console.log(`Execute  setMinter`);
  console.log(`Token: ${TOKEN_ADDRESS}`);
  console.log(`Minter: ${MINTER_ADDRESS}`);
};

export default func;
func.tags = ["SetMinter"];
