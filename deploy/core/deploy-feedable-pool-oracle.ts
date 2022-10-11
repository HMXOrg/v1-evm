import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const MockPoolOracle = await ethers.getContractFactory(
    "MockPoolOracle",
    deployer
  );
  const mockPoolOracle = await MockPoolOracle.deploy();
  await mockPoolOracle.deployed();
  console.log(`Deploying MockPoolOracle Token Contract`);
  console.log(`Deployed at: ${mockPoolOracle.address}`);

  await tenderly.verify({
    address: mockPoolOracle.address,
    name: "FeedablePoolOracle",
  });

  config.Pools.PLP.oracle = mockPoolOracle.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["MockPoolOracle"];
