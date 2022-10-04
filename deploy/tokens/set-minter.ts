import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MintableTokenInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.esP88;
const MINTER_ADDRESSES = ["0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a"];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = MintableTokenInterface__factory.connect(
    TOKEN_ADDRESS,
    deployer
  );
  for (let i = 0; i < MINTER_ADDRESSES.length; i++) {
    const tx = await token.setMinter(MINTER_ADDRESSES[i], true);
    const txReceipt = await tx.wait();
    console.log(`Execute  setMinter`);
    console.log(`Token: ${TOKEN_ADDRESS}`);
    console.log(`Minter: ${MINTER_ADDRESSES[i]}`);
  }
};

export default func;
func.tags = ["SetMinter"];
