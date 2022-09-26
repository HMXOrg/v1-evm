import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const EsP88 = await ethers.getContractFactory("EsP88", deployer);
  const esP88 = await EsP88.deploy(false);
  console.log(`Deploying EsP88 Token Contract`);
  console.log(`Deployed at: ${esP88.address}`);

  config.Tokens.esP88 = esP88.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: esP88.address,
    name: "EsP88",
  });
};

export default func;
func.tags = ["EsP88Token"];
