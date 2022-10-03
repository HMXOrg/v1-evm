import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const MockERC20 = await ethers.getContractFactory("MockERC20", deployer);
  const mockERC20 = await MockERC20.deploy("Quickswap LP", "QLP");
  await mockERC20.deployed();
  console.log(`Deploying MockERC20 Token Contract`);
  console.log(`Deployed at: ${mockERC20.address}`);

  await tenderly.verify({
    address: mockERC20.address,
    name: "MockERC20",
  });

  config.Tokens.P88QSLP = mockERC20.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["MockERC20Token"];
