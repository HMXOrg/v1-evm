import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PerpTradeFacet = await ethers.getContractFactory(
    "PerpTradeFacet",
    deployer
  );

  console.log(`Deploying PerpTradeFacet Contract`);
  const perpTradeFacet = await PerpTradeFacet.deploy();
  await perpTradeFacet.deployTransaction.wait(3);
  console.log(`Deployed at: ${perpTradeFacet.address}`);

  config.Pools.PLP.facets.perpTrade = perpTradeFacet.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: perpTradeFacet.address,
    name: "PerpTradeFacet",
  });
};

export default func;
func.tags = ["PerpTradeFacet"];
