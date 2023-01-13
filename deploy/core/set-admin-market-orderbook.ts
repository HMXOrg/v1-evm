import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AdminFacetInterface__factory,
  MarketOrderbook__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const ADMIN = "0x6a5D2BF8ba767f7763cd342Cb62C5076f9924872"; // DEPLOYER

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const orderbook = MarketOrderbook__factory.connect(
    config.Pools.PLP.marketOrderbook,
    deployer
  );

  console.log(`> Set Admin...`);
  const tx = await orderbook.setAdmin(ADMIN, {
    ...(await eip1559rapidGas()),
  });
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Tx mined!`);
};

export default func;
func.tags = ["SetAdminMarketOrderbook"];
