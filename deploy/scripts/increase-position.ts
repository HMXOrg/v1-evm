import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  MintableTokenInterface__factory,
  PoolRouter__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const POOL_ROUTER = config.PoolRouter;
const COLLATERAL_TOKEN = config.Tokens.WBTC;
const INDEX_TOKEN = config.Tokens.WBTC;
const isLong = true;

enum Exposure {
  LONG,
  SHORT,
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const poolRouter = PoolRouter__factory.connect(POOL_ROUTER, deployer);
  const collateralToken = ERC20__factory.connect(COLLATERAL_TOKEN, deployer);
  const decimals = await collateralToken.decimals();

  await (
    await collateralToken.approve(
      poolRouter.address,
      ethers.constants.MaxUint256
    )
  ).wait();

  await (
    await poolRouter.increasePosition(
      config.Pools.PLP.poolDiamond,
      0,
      COLLATERAL_TOKEN,
      COLLATERAL_TOKEN,
      ethers.utils.parseUnits("1", decimals),
      0,
      INDEX_TOKEN,
      ethers.utils.parseUnits("40000", 30),
      isLong,
      ethers.constants.MaxUint256,
      { gasLimit: 10000000 }
    )
  ).wait();
  console.log(`Execute increasePosition`);
};

export default func;
func.tags = ["IncreasePosition"];
