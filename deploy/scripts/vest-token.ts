import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, Vester__factory } from "../../typechain";

const TOKEN_ADDRESS = "0xB853c09b6d03098b841300daD57701ABcFA80228";
const VESTER = "0x0e6441C3D17c401030F5bea80aDc993a44926b91";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = ERC20__factory.connect(TOKEN_ADDRESS, deployer);
  await (await token.approve(VESTER, ethers.constants.MaxUint256)).wait();
  const stakingContract = Vester__factory.connect(VESTER, deployer);
  await (
    await stakingContract.vestFor(
      deployer.address,
      ethers.utils.parseEther("1"),
      10
    )
  ).wait();
  console.log(`Execute vestFor`);
};

export default func;
func.tags = ["VestToken"];
