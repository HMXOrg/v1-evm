import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const startLockTimestamp = 0;
const plpStaking = "0x7AAF085e43f059105F7e1ECc525E8142fF962159";
const plpToken = "0xc88322Ec9526A7A98B7F58ff773b3B003C91ce71";
const p88Token = "0xB853c09b6d03098b841300daD57701ABcFA80228";
const gatewayAddress = "0x07bE4AE3E0454D09b3D3cfe63538A9F0970aE32d";
const lockdropCompounder = "0xDAf969875e355B808e376e649617FDa5b9E73e1C";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const LockdropConfig = await ethers.getContractFactory(
    "LockdropConfig",
    deployer
  );
  const lockdropConfig = await upgrades.deployProxy(LockdropConfig, [
    startLockTimestamp,
    plpStaking,
    plpToken,
    p88Token,
    gatewayAddress,
    lockdropCompounder,
  ]);
  await lockdropConfig.deployed();
  console.log(`Deploying LockdropConfig Contract`);
  console.log(`Deployed at: ${lockdropConfig.address}`);
};

export default func;
func.tags = ["LockdropConfig"];
