import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLPStaking__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const COMPOUNDER_ADDRESS = config.Staking.Compounder;
const STAKING_CONTRACT_ADDRESS = [
  config.Staking.PLPStaking.address,
  config.Staking.DragonStaking.address,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  for (let i = 0; i < STAKING_CONTRACT_ADDRESS.length; i++) {
    const stakingContract = PLPStaking__factory.connect(
      STAKING_CONTRACT_ADDRESS[i],
      deployer
    );
    const tx = await stakingContract.setCompounder(COMPOUNDER_ADDRESS);
    const txReceipt = await tx.wait();
    console.log(`Execute  setCompounder`);
    console.log(`Staking Contract: ${STAKING_CONTRACT_ADDRESS[i]}`);
    console.log(`Compounder: ${COMPOUNDER_ADDRESS}`);
  }
};

export default func;
func.tags = ["SetCompounder"];
