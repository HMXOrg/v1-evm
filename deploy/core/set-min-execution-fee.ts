import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AdminFacetInterface__factory,
  Orderbook__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const plugin = config.Pools.PLP.orderbook;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const orderbook = Orderbook__factory.connect(
    config.Pools.PLP.orderbook,
    deployer
  );
  const tx = await orderbook.setMinExecutionFee(
    ethers.utils.parseEther("0.001")
  );
  const txReceipt = await tx.wait();
  console.log(`Execute setMinExecutionFee`);
};

export default func;
func.tags = ["SetMinExecutionFee"];
