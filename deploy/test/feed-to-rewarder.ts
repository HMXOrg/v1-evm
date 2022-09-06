import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, FeedableRewarder__factory } from "../../typechain";
import { BigNumber } from "ethers";

const TOKEN_ADDRESS = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";
const REWARDER_ADDRESS = "0x28826219ffb76aa41a56a40e875709391795e512";
const AMOUNT = "500";
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
