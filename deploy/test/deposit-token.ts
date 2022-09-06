import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, PLPStaking__factory } from "../../typechain";

const TOKEN_ADDRESS = "0xc88322Ec9526A7A98B7F58ff773b3B003C91ce71";
const STAKING_CONTRACT = "0xCB1EaA1E9Fd640c3900a4325440c80FEF4b1b16d";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = ERC20__factory.connect(TOKEN_ADDRESS, deployer);
  await (
    await token.approve(STAKING_CONTRACT, ethers.constants.MaxUint256)
  ).wait();
  const stakingContract = PLPStaking__factory.connect(
    STAKING_CONTRACT,
    deployer
  );
  await (
    await stakingContract.deposit(
      deployer.address,
      TOKEN_ADDRESS,
      ethers.utils.parseEther("1")
    )
  ).wait();
  console.log(`Execute deposit`);
};

export default func;
func.tags = ["DepositToken"];
