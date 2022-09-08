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
const COLLATERAL_TOKEN = config.Tokens.DAI;

enum Exposure {
  LONG,
  SHORT,
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const poolRouter = PoolRouter__factory.connect(POOL_ROUTER, deployer);
  const collateralToken = ERC20__factory.connect(COLLATERAL_TOKEN, deployer);

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
      ethers.utils.parseUnits("1000", 18),
      config.Tokens.WBTC,
      ethers.utils.parseUnits("10000", 30),
      false,
      ethers.constants.Zero,
      { gasLimit: 10000000 }
    )
  ).wait();
  console.log(`Execute increasePosition`);
};

export default func;
func.tags = ["IncreasePosition"];
