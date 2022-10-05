import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, PoolRouter__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.WBTC;
const POOL_ROUTER = config.PoolRouter;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = ERC20__factory.connect(TOKEN_ADDRESS, deployer);
  const decimals = await token.decimals();
  await (await token.approve(POOL_ROUTER, ethers.constants.MaxUint256)).wait();
  const poolRouter = PoolRouter__factory.connect(POOL_ROUTER, deployer);
  await (
    await poolRouter.addLiquidity(
      config.Pools.PLP.poolDiamond,
      TOKEN_ADDRESS,
      ethers.utils.parseUnits("50", decimals),
      deployer.address,
      0
    )
  ).wait();
  console.log(`Execute addLiquidity`);
};

export default func;
func.tags = ["BuyPLP"];
