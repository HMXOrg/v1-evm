import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AdminFacetInterface__factory,
  Orderbook__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const WHITELIST_ADDRESS = "0x3A16765161fEeC1E5d8a80020d4974e5032A23B1";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const orderbook = Orderbook__factory.connect(
    config.Pools.PLP.orderbook,
    deployer
  );

  console.log(`> Set Orderbook's whitelist...`);
  const tx = await orderbook.setWhitelist(
    WHITELIST_ADDRESS,
    true,
    await eip1559rapidGas()
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Tx mined!`);
};

export default func;
func.tags = ["SetWhitelistOrderbook"];
