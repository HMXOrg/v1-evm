import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  MintableTokenInterface__factory,
  PoolRouter__factory,
} from "../../typechain";
import config from "../../contracts.mumbai.json";

const POOL_ROUTER = config.PoolRouter;
const COLLATERAL_TOKEN = config.Tokens.WBTC;
const POOL = config.Pools[0].address;

enum Exposure {
  LONG,
  SHORT,
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const poolRouter = PoolRouter__factory.connect(POOL_ROUTER, deployer);
  const collateralToken = ERC20__factory.connect(COLLATERAL_TOKEN, deployer);

  // await (
  //   await collateralToken.approve(
  //     poolRouter.address,
  //     ethers.constants.MaxUint256
  //   )
  // ).wait();

  // await (
  //   await poolRouter.increasePosition(
  //     POOL,
  //     0,
  //     COLLATERAL_TOKEN,
  //     ethers.utils.parseUnits("1", 8),
  //     COLLATERAL_TOKEN,
  //     ethers.utils.parseUnits("50000", 30),
  //     Exposure.LONG,
  //     { gasLimit: 10000000 }
  //   )
  // ).wait();
  console.log(`Execute increasePosition`);
};

export default func;
func.tags = ["IncreasePosition"];
