import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LiquidityFacet = await ethers.getContractFactory(
    "LiquidityFacet",
    deployer
  );
  const liquidityFacet = await LiquidityFacet.deploy();
  liquidityFacet.deployed();
  console.log(`Deploying LiquidityFacet Contract`);
  console.log(`Deployed at: ${liquidityFacet.address}`);
};

export default func;
func.tags = ["LiquidityFacet"];
