import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLPStaking__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const STAKING_CONTRACT_ADDRESS = config.Staking.DragonStaking.address;
const STAKING_TOKEN_ADDRESS = config.Tokens.DragonPoint;
const REWARDERS = config.Staking.DragonStaking.rewarders
  .filter((each: any) => each.name === "Dragon Staking Protocol Revenue")
  .map((each: any) => each.address);

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const stakingContract = PLPStaking__factory.connect(
    STAKING_CONTRACT_ADDRESS,
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
