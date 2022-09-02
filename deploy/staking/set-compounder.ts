import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLPStaking__factory } from "../../typechain";

const COMPOUNDER_ADDRESS = "0x0aA6DD7D094F1773fD7D91427232bA178F6fb955";
const STAKING_CONTRACT_ADDRESS = [
  "0x7AAF085e43f059105F7e1ECc525E8142fF962159",
  "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d",
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
