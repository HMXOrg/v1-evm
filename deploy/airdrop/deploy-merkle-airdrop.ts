import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const feeder = "0x6629eC35c8Aa279BA45Dbfb575c728d3812aE31a";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const MerkleAirdrop = await ethers.getContractFactory(
    "MerkleAirdrop",
    deployer
  );
  const merkleAirdrop = await MerkleAirdrop.deploy(config.Tokens.USDC, feeder);
  await merkleAirdrop.deployed();
  console.log(`Deploying MerkleAirdrop Contract`);
  console.log(`Deployed at: ${merkleAirdrop.address}`);

  config.MerkleAirdrop.address = merkleAirdrop.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: merkleAirdrop.address,
    name: "MerkleAirdrop",
  });
};

export default func;
func.tags = ["MerkleAirdrop"];
