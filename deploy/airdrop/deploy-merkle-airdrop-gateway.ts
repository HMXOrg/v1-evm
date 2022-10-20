import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const MerkleAirdropGateway = await ethers.getContractFactory(
    "MerkleAirdropGateway",
    deployer
  );
  const merkleAirdropGateway = await MerkleAirdropGateway.deploy();
  await merkleAirdropGateway.deployed();
  console.log(`Deploying MerkleAirdropGateway Contract`);
  console.log(`Deployed at: ${merkleAirdropGateway.address}`);

  config.ReferralDistribution.MerkleAirdropGateway.address =
    merkleAirdropGateway.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: merkleAirdropGateway.address,
    name: "MerkleAirdropGateway",
  });
};

export default func;
func.tags = ["MerkleAirdropGateway"];
