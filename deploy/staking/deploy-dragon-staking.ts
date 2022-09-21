import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const DRAGON_POINT_TOKEN_ADDRESS = config.Tokens.DragonPoint;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const DragonStaking = await ethers.getContractFactory(
    "DragonStaking",
    deployer
  );
  const dragonStaking = await upgrades.deployProxy(DragonStaking, [
    DRAGON_POINT_TOKEN_ADDRESS,
  ]);
  await dragonStaking.deployed();
  console.log(`Deploying DragonStaking Contract`);
  console.log(`Deployed at: ${dragonStaking.address}`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    dragonStaking.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "DragonStaking",
  });

  config.Staking.DragonStaking.address = dragonStaking.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["DragonStaking"];
