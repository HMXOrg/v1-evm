import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLPStaking__factory } from "../../typechain";

const COMPOUNDER_ADDRESS = "0x4B7e63B556F9c4A6b915d6e164658111b8F39FD8";
const STAKING_CONTRACT_ADDRESS = [
  "0x818Eb7fbaeeddA8959046439fcC4A6C7C749b412",
  "0x5c0F9425AB82AD53b009f02b2C2857544E74CC86",
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
