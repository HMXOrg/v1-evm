import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { BaseStaking__factory } from "../../typechain";

const STAKING_TOKEN_ADDRESS = "0x2Ce4E6CC667463e4695992dDD648C44CF2d00519";
const REWARDERS = [
  "0x7c65D42a392694927FE402cE9468E2C2baFce2b0",
  "0x2Bc554B886c29AeBFeE5b9081F8A2644Baf1740c",
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const stakingContract = BaseStaking__factory.connect(
    "0xa80633E7B66f9Bf4eD75503A5460A645Ef06B510",
    deployer
  );
  const tx = await stakingContract.addStakingToken(
    STAKING_TOKEN_ADDRESS,
    REWARDERS
  );
  const txReceipt = await tx.wait();
  console.log(`Execute  addStakingToken`);
  console.log(`Staking Token: ${STAKING_TOKEN_ADDRESS}`);
  console.log(`Rewarders: ${REWARDERS}`);
};

export default func;
func.tags = ["AddStakingToken"];
