import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const MerkleAirdrop = await ethers.getContractFactory(
    "MerkleAirdrop",
    deployer
  );
  const merkleAirdrop = await MerkleAirdrop.deploy();
  await merkleAirdrop.deployed();
  console.log(`Deploying MerkleAirdrop Contract`);
  console.log(`Deployed at: ${merkleAirdrop.address}`);

  await tenderly.verify({
    address: merkleAirdrop.address,
    name: "MerkleAirdrop",
  });

  config.ReferralDistribution.MerkleAirdropTemplate = merkleAirdrop.address;
  writeConfigFile(config);
};

export default func;
func.tags = ["MerkleAirdrop"];
