import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MintableTokenInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.DragonPoint;
const MINTER_ADDRESSES = [
  config.Staking.DragonStaking.address,
  config.Staking.DragonStaking.rewarders.find(
    (each) => each.name === "Dragon Staking Dragon Point Emission"
  )!.address,
];

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
