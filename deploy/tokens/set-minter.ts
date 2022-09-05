import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MintableTokenInterface__factory } from "../../typechain";

const TOKEN_ADDRESS = "0xBb5e11926b8040ccFa67045aF552F47C735CfF87";
const MINTER_ADDRESSES = ["0xC90466D18C402a0395CCe0B165D9fA1ae5CE43cB"];

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
