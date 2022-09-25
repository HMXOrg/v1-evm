import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { DragonPoint__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.DragonPoint;
const TRANSFERRER_ADDRESSES = [
  config.Staking.DragonStaking.address,
  config.Staking.DragonStaking.rewarders.find(
    (each) => each.name === "Dragon Staking Dragon Point Emission"
  )!.address,
  config.Staking.Compounder,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = DragonPoint__factory.connect(TOKEN_ADDRESS, deployer);
  for (let i = 0; i < TRANSFERRER_ADDRESSES.length; i++) {
    const tx = await token.setTransferrer(TRANSFERRER_ADDRESSES[i], true);
    const txReceipt = await tx.wait();
    console.log(`Execute  setTransferrer`);
    console.log(`Token: ${TOKEN_ADDRESS}`);
    console.log(`Transferrer: ${TRANSFERRER_ADDRESSES[i]}`);
  }
};

export default func;
func.tags = ["SetTransferrer"];
