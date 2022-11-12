import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PLPStaking__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { eip1559rapidGas } from "../utils/gas";

const config = getConfig();

const COMPOUNDER_ADDRESS = config.Staking.Compounder;
const STAKING_CONTRACT_ADDRESS = [config.Staking.PLPStaking.address];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  for (let i = 0; i < STAKING_CONTRACT_ADDRESS.length; i++) {
    console.log(
      `> Setting Compounder on ${STAKING_CONTRACT_ADDRESS[i]} [${i + 1}/${
        STAKING_CONTRACT_ADDRESS.length
      }]`
    );
    const stakingContract = PLPStaking__factory.connect(
      STAKING_CONTRACT_ADDRESS[i],
      deployer
    );
    const tx = await stakingContract.setCompounder(
      COMPOUNDER_ADDRESS,
      await eip1559rapidGas()
    );
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    tx.wait(3);
    console.log(`> Tx is mined`);
  }

  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetCompounder"];
