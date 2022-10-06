import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MintableTokenInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();
const TOKEN_ADDRESS = config.Tokens.esP88;
const MINT_TO = "0x6629ec35c8aa279ba45dbfb575c728d3812ae31a";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = MintableTokenInterface__factory.connect(
    TOKEN_ADDRESS,
    deployer
  );
  const tx = await token.mint(MINT_TO, ethers.utils.parseUnits("10000000", 18));
  const txReceipt = await tx.wait();
  console.log(`Execute  mint`);
  console.log(`Token: ${TOKEN_ADDRESS}`);
  console.log(`Mint to: ${MINT_TO}`);
};

export default func;
func.tags = ["MintToken"];
