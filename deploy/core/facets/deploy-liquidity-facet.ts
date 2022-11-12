import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LiquidityFacet = await ethers.getContractFactory(
    "LiquidityFacet",
    deployer
  );

  console.log(`Deploying LiquidityFacet Contract`);
  const liquidityFacet = await LiquidityFacet.deploy();
  await liquidityFacet.deployTransaction.wait(3);
  console.log(`Deployed at: ${liquidityFacet.address}`);

  config.Pools.PLP.facets.liquidity = liquidityFacet.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: liquidityFacet.address,
    name: "LiquidityFacet",
  });
};

export default func;
func.tags = ["LiquidityFacet"];
