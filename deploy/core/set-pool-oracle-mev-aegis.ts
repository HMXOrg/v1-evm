import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AdminFacetInterface__factory,
  MEVAegis__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const mevAegis = MEVAegis__factory.connect(
    config.Pools.PLP.mevAegis,
    deployer
  );
  const tx = await mevAegis.setPoolOracle(
    config.Pools.PLP.oracle,
    await eip1559rapidGas()
  );
  const txReceipt = await tx.wait();
  console.log(`Execute setPoolOracle for MEVAegis`);
};

export default func;
func.tags = ["SetPoolOracleMEVAegis"];
