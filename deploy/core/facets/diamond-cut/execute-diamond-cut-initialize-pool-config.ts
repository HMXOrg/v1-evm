import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DiamondCutFacet__factory,
  PoolConfigInitializer__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

const treasury = "0x6629ec35c8aa279ba45dbfb575c728d3812ae31a";
const fundingInterval = 60 * 60; // 1 hour
const mintBurnFeeBps = 30;
const taxBps = 50;
const stableBorrowingRateFactor = 100; // 0.01% / 1 hour
const fundingRateFactor = 25; // 0.0025% / 1 hour
const borrowingRateFactor = 100; // 0.01% / 1 hour
const liquidationFeeUsd = ethers.utils.parseUnits("5", 30);

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  await (
    await poolDiamond.diamondCut(
      [],
      config.Pools.PLP.facets.poolConfigInitializer,
      PoolConfigInitializer__factory.createInterface().encodeFunctionData(
        "initialize",
        [
          treasury,
          fundingInterval,
          mintBurnFeeBps,
          taxBps,
          stableBorrowingRateFactor,
          borrowingRateFactor,
          fundingRateFactor,
          liquidationFeeUsd,
        ]
      )
    )
  ).wait();

  console.log(`Execute diamondCut for InitializePoolConfig`);
};

export default func;
func.tags = ["ExecuteDiamondCut-InitializePoolConfig"];
