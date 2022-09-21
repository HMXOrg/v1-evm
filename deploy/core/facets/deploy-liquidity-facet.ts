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
  const liquidityFacet = await LiquidityFacet.deploy();
  await liquidityFacet.deployed();
  console.log(`Deploying LiquidityFacet Contract`);
  console.log(`Deployed at: ${liquidityFacet.address}`);

  await tenderly.verify({
    address: liquidityFacet.address,
    name: "LiquidityFacet",
  });

  config.Pools.PLP.facets.liquidity = liquidityFacet.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["LiquidityFacet"];
