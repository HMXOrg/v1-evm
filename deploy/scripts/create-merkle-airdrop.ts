import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AccessControlFacetInterface__factory,
  MerkleAirdropFactory__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";
import { BigNumber } from "ethers";
import * as fileHelpers from "../utils/file";

interface MerkleTree {
  merkleRoot: string;
  weekTimestamp: number;
  tokenTotal: string;
  ipfsHash: string;
}

const config = getConfig();
const merkleTreePath = "referral-merkle-tree-week-2750.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const currentBlockNumber = await ethers.provider.getBlockNumber();
  const currentBlock = await ethers.provider.getBlock(currentBlockNumber);

  const merkleTree = (await fileHelpers.readJson(merkleTreePath)) as MerkleTree;

  const template = config.ReferralDistribution.MerkleAirdropTemplate.address;
  const token = config.Tokens.USDC;
  const merkleRoot = merkleTree.merkleRoot;
  const expireTimestamp = currentBlock.timestamp + 60 * 60 * 24 * 365; // 1 year
  const weekTimestamp = 2750;
  const totalAmountToDistribute = BigNumber.from(merkleTree.tokenTotal);
  const salt = ethers.utils.solidityKeccak256(
    ["string"],
    [
      ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256"],
        [weekTimestamp, totalAmountToDistribute]
      ),
    ]
  );
  const ipfsHash = merkleTree.ipfsHash;

  const deployer = (await ethers.getSigners())[0];
  const factory = MerkleAirdropFactory__factory.connect(
    config.ReferralDistribution.MerkleAirdropFactory.address,
    deployer
  );

  console.log("Execute CreateMerkleAirdrop");
  const tx = await (
    await factory.createMerkleAirdrop(
      template,
      token,
      merkleRoot,
      expireTimestamp,
      salt,
      ipfsHash
    )
  ).wait();
  const newMerkleAirdropAddress = await factory.computeMerkleAirdropAddress(
    template,
    salt
  );
  console.log(
    `Sucessfully created Merkle Airdrop at ${newMerkleAirdropAddress}`
  );
  console.log(`Week Timestamp: ${weekTimestamp}`);
  console.log(
    `Total USDC Amount: ${ethers.utils.formatUnits(totalAmountToDistribute, 6)}`
  );
};

export default func;
func.tags = ["CreateMerkleAirdrop"];
