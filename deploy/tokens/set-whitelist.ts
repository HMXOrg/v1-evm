import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLP__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const WHITELIST_ADDRESSES = [
  config.Staking.PLPStaking.address,
  config.PoolRouter,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = PLP__factory.connect(config.Tokens.PLP, deployer);
  for (let i = 0; i < WHITELIST_ADDRESSES.length; i++) {
    const tx = await token.setWhitelist(WHITELIST_ADDRESSES[i], true);
    const txReceipt = await tx.wait();
    console.log(`Execute  setWhitelist for PLP`);
    console.log(`Minter: ${WHITELIST_ADDRESSES[i]}`);
  }
};

export default func;
func.tags = ["SetWhitelist"];
