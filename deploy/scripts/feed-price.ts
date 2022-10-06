import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, PoolRouter__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { FeedablePoolOracle__factory } from "../../typechain/factories/src/core/FeedablePoolOracle__factory";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const oracle = FeedablePoolOracle__factory.connect(
    config.Pools.PLP.oracle,
    deployer
  );
  await oracle.feedMinPrice(
    config.Tokens.WMATIC,
    ethers.utils.parseUnits("0.82", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.WMATIC,
    ethers.utils.parseUnits("0.82", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.WBTC,
    ethers.utils.parseUnits("20000", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.WBTC,
    ethers.utils.parseUnits("20000", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.WETH,
    ethers.utils.parseUnits("1360", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.WETH,
    ethers.utils.parseUnits("1360", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.DAI,
    ethers.utils.parseUnits("1", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.DAI,
    ethers.utils.parseUnits("1", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.USDT,
    ethers.utils.parseUnits("1", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.USDT,
    ethers.utils.parseUnits("1", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.USDC,
    ethers.utils.parseUnits("1", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.USDC,
    ethers.utils.parseUnits("1", 30)
  );
  console.log("Done");
};

export default func;
func.tags = ["FeedPrice"];
