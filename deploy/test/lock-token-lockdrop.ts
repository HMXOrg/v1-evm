import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  LockdropGateway__factory,
  PLPStaking__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.WBTC;
const GATEWAY = config.Lockdrop.gateway;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = ERC20__factory.connect(TOKEN_ADDRESS, deployer);
  const tokenDecimals = await token.decimals();
  await (await token.approve(GATEWAY, ethers.constants.MaxUint256)).wait();
  const gateway = LockdropGateway__factory.connect(GATEWAY, deployer);
  await (
    await gateway.lockToken(
      TOKEN_ADDRESS,
      ethers.utils.parseUnits("1", tokenDecimals),
      604800,
      { gasLimit: 10000000 }
    )
  ).wait();
  console.log(`Execute lockToken`);
};

export default func;
func.tags = ["LockTokenLockdrop"];
