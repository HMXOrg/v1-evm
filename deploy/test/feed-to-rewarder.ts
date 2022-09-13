import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, FeedableRewarder__factory } from "../../typechain";
import { BigNumber } from "ethers";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.WMATIC;
const REWARDER_ADDRESS = config.Staking.DragonStaking.rewarders.find(
  (each: any) => each.name === "Dragon Staking Protocol Revenue"
).address;
const AMOUNT = "0.1";
const DURATION = "604800";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const rewarder = FeedableRewarder__factory.connect(
    REWARDER_ADDRESS,
    deployer
  );
  const token = ERC20__factory.connect(TOKEN_ADDRESS, deployer);
  await (
    await token.approve(REWARDER_ADDRESS, ethers.constants.MaxUint256)
  ).wait();
  const tx = await rewarder.feed(
    ethers.utils.parseEther(AMOUNT),
    BigNumber.from(DURATION)
  );
  const txReceipt = await tx.wait();
  console.log(`Execute feedToRewarder`);
  console.log(`Rewarder: ${REWARDER_ADDRESS}`);
};

export default func;
func.tags = ["FeedToRewarder"];