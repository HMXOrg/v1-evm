import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MintableTokenInterface__factory } from "../../typechain";

const TOKEN_ADDRESS = "0xc88322Ec9526A7A98B7F58ff773b3B003C91ce71";
const MINTER_ADDRESSES = ["0x5A11B2328862527151fD2e7EaE02455E2e6b1d31"];

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