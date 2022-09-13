import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PerpTradeFacet = await ethers.getContractFactory(
    "PerpTradeFacet",
    deployer
  );
  const perpTradeFacet = await PerpTradeFacet.deploy();
  perpTradeFacet.deployed();
  console.log(`Deploying PerpTradeFacet Contract`);
  console.log(`Deployed at: ${perpTradeFacet.address}`);
};

export default func;
func.tags = ["PerpTradeFacet"];
