import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  GetterFacet__factory,
  Lockdrop__factory,
  PLPStaking__factory,
  PoolOracle__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();
const BigNumber = ethers.BigNumber;
const collateralToken = config.Tokens.WBTC;
const indexToken = config.Tokens.WBTC;
const isLong = true;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const lockdrop = Lockdrop__factory.connect(
    "0x560dc88c27F2338d17887878E86b88CD618E3F75",
    deployer
  );
  console.log(
    await lockdrop.lockdropStates("0x53a5466667a08ff36b0e8f1129071cc74473fd59")
  );
  console.log(await lockdrop.totalAmount());
  const pendingReward = await lockdrop.pendingReward(
    "0x53a5466667a08ff36b0e8f1129071cc74473fd59"
  );
  console.log("pendingReward", pendingReward);
};

export default func;
func.tags = ["ReadData"];
