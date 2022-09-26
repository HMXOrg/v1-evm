import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DiamondCutFacet = await ethers.getContractFactory(
    "DiamondCutFacet",
    deployer
  );

  console.log(`Deploying DiamondCutFacet Contract`);
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.deployed();
  console.log(`Deployed at: ${diamondCutFacet.address}`);

  config.Pools.PLP.facets.diamondCut = diamondCutFacet.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: diamondCutFacet.address,
    name: "DiamondCutFacet",
  });
};

export default func;
func.tags = ["DiamondCutFacet"];
