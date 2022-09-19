import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const NAME = "Dragon Staking Dragon Point Emission";
const REWARD_TOKEN_ADDRESS = config.Tokens.DragonPoint;
const STAKING_CONTRACT_ADDRESS = config.Staking.DragonStaking.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Rewarder = await ethers.getContractFactory(
    "AdHocMintRewarder",
    deployer
  );
  const rewarder = await upgrades.deployProxy(Rewarder, [
    NAME,
    REWARD_TOKEN_ADDRESS,
    STAKING_CONTRACT_ADDRESS,
  ]);
  await rewarder.deployed();
  console.log(`Deploying ${NAME} AdHocMintRewarder Contract`);
  console.log(`Deployed at: ${rewarder.address}`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    rewarder.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "AdHocMintRewarder",
  });

  config.Staking.DragonStaking.rewarders =
    config.Staking.DragonStaking.rewarders.map((each: any) => {
      if (each.name === NAME) {
        return {
          ...each,
          address: rewarder.address,
          rewardToken: REWARD_TOKEN_ADDRESS,
        };
      } else return each;
    });
  writeConfigFile(config);
};

export default func;
func.tags = ["AdHocMintRewarder"];
