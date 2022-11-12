import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLP__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const WHITELIST_ADDRESSES = [
  config.Staking.PLPStaking.address,
  config.PoolRouter,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = PLP__factory.connect(config.Tokens.PLP, deployer);
  for (let i = 0; i < WHITELIST_ADDRESSES.length; i++) {
    console.log(
      `> Adding ${WHITELIST_ADDRESSES[i]} [${i + 1}/${
        WHITELIST_ADDRESSES.length
      }] to PLP's whitelist`
    );
    const tx = await token.setWhitelist(
      WHITELIST_ADDRESSES[i],
      true,
      await eip1559rapidGas()
    );
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    tx.wait(3);
    console.log(`> Tx is mined`);
  }
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetWhitelist"];
