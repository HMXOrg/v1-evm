import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, PLPStaking__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const STAKING_CONTRACT_ADDRESS = config.Staking.PLPStaking.address;
const STAKING_TOKEN_ADDRESS = config.Tokens.PLP;
const REWARDERS = config.Staking.PLPStaking.rewarders
  .map((each: any) => each.address)
  .filter((each) => each !== ethers.constants.AddressZero);

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const stakingContract = PLPStaking__factory.connect(
    STAKING_CONTRACT_ADDRESS,
    deployer
  );
  const newStakingToken = ERC20__factory.connect(
    STAKING_TOKEN_ADDRESS,
    deployer
  );
  const newStakingTokenSymbol = await newStakingToken.symbol();

  console.log(`> Adding ${newStakingTokenSymbol} to staking contract`);
  const tx = await stakingContract.addStakingToken(
    STAKING_TOKEN_ADDRESS,
    REWARDERS,
    await eip1559rapidGas()
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["AddStakingToken"];
