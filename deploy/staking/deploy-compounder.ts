import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const DESTINATION_COMPUND_POOL = "0x5c0F9425AB82AD53b009f02b2C2857544E74CC86";
const TOKENS = [
  "0x980cDd680Ea324ABaa6C64df31fDA73e35aC6c90",
  "0x41E01292699513Fb5b202f97b98B361BF39E7c5F",
];
const IS_COMPOUNDABLE_TOKENS = [true, true];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Compounder = await ethers.getContractFactory("Compounder", deployer);
  const compounder = await Compounder.deploy(
    DESTINATION_COMPUND_POOL,
    TOKENS,
    IS_COMPOUNDABLE_TOKENS
  );
  console.log(`Deploying Compounder Contract`);
  console.log(`Deployed at: ${compounder.address}`);
};

export default func;
func.tags = ["Compounder"];
