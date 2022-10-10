import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  MintableTokenInterface__factory,
  Orderbook__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const ORDERBOOK = config.Pools.PLP.orderbook;
const COLLATERAL_TOKEN = config.Tokens.WBTC;
const INDEX_TOKEN = config.Tokens.WBTC;
const isLong = true;

enum Exposure {
  LONG,
  SHORT,
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const orderbook = Orderbook__factory.connect(ORDERBOOK, deployer);
  const collateralToken = ERC20__factory.connect(COLLATERAL_TOKEN, deployer);
  const decimals = await collateralToken.decimals();

  await (
    await collateralToken.approve(
      orderbook.address,
      ethers.constants.MaxUint256
    )
  ).wait();
  const minExecutionFee = await orderbook.minExecutionFee();
  await (
    await orderbook.createIncreaseOrder(
      2,
      [COLLATERAL_TOKEN],
      ethers.utils.parseUnits("1", decimals),
      INDEX_TOKEN,
      0,
      ethers.utils.parseUnits("40000", 30),
      COLLATERAL_TOKEN,
      isLong,
      ethers.utils.parseUnits("19500", 30),
      false,
      minExecutionFee,
      false,
      { value: minExecutionFee }
    )
  ).wait();
  console.log(`Execute createIncreaseOrder`);
};

export default func;
func.tags = ["CreateIncreaseOrder"];
