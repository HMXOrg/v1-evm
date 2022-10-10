import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MintableTokenInterface__factory } from "../../typechain";

const TOKEN_ADDRESS = "0xc88322Ec9526A7A98B7F58ff773b3B003C91ce71";
const MINT_TO = "0x6629ec35c8aa279ba45dbfb575c728d3812ae31a";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = MintableTokenInterface__factory.connect(
    TOKEN_ADDRESS,
    deployer
  );
  const tx = await token.burn(MINT_TO, ethers.utils.parseEther("150000000"));
  const txReceipt = await tx.wait();
  console.log(`Execute burn`);
  console.log(`Token: ${TOKEN_ADDRESS}`);
  console.log(`Burn from: ${MINT_TO}`);
};

export default func;
func.tags = ["BurnToken"];
