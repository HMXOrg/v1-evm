import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, FeedableRewarder__factory } from "../../typechain";
import { BigNumber } from "ethers";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.USDC;
const REWARDER_ADDRESS = (
  config.Staking.PLPStaking.rewarders.find(
    (each: any) => each.name === "PLP Staking Protocol Revenue"
  ) as any
).address;
const AMOUNT = "100000";
const DURATION = "604800";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const rewarder = FeedableRewarder__factory.connect(
    REWARDER_ADDRESS,
    deployer
  );
  const token = ERC20__factory.connect(TOKEN_ADDRESS, deployer);
  const decimals = await token.decimals();
  await (
    await token.approve(REWARDER_ADDRESS, ethers.constants.MaxUint256)
  ).wait();
  const tx = await rewarder.feed(
    ethers.utils.parseUnits(AMOUNT, decimals),
    BigNumber.from(DURATION),
    { gasLimit: 10000000 }
  );
  const txReceipt = await tx.wait();
  console.log(`Execute feedToRewarder`);
  console.log(`Rewarder: ${REWARDER_ADDRESS}`);
};

export default func;
func.tags = ["FeedToRewarder"];
