import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { Ownable__factory } from "../../typechain";

const config = getConfig();
const contracts: string[] = [
  config.Tokens.PLP,
  config.Pools.PLP.oracle,
  config.Pools.PLP.orderbook,
  config.Staking.Compounder,
  config.Staking.PLPStaking.address,
  config.Staking.PLPStaking.rewarders[0].address,
  config.Staking.RewardDistributor.address,
  config.MerkleAirdrop.address,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  for (let i = 0; i < contracts.length; i++) {
    console.log(
      `Transferring ownership of ${contracts[i]} to Timelock at ${config.Timelock}`
    );
    const contract = Ownable__factory.connect(contracts[i], deployer);
    const tx = await contract.transferOwnership(config.Timelock);
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    await tx.wait(3);
    console.log(`> Success`);
  }
  console.log(`> All Done`);
};

export default func;
func.tags = ["SetOwnerToTimelock"];
