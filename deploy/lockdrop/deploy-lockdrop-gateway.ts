import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const plpToken = "0xc88322Ec9526A7A98B7F58ff773b3B003C91ce71";
const plpStaking = "0x7AAF085e43f059105F7e1ECc525E8142fF962159";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LockdropGateway = await ethers.getContractFactory(
    "LockdropGateway",
    deployer
  );
  const lockdropGateway = await upgrades.deployProxy(LockdropGateway, [
    plpToken,
    plpStaking,
  ]);
  await lockdropGateway.deployed();
  console.log(`Deploying LockdropGateway Contract`);
  console.log(`Deployed at: ${lockdropGateway.address}`);
};

export default func;
func.tags = ["LockdropGateway"];
