import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DiamondCutFacet__factory,
  DiamondLoupeFacet__factory,
  FundingRateFacet__factory,
  GetterFacet__factory,
  LiquidityFacetInterface__factory,
  OwnershipFacet__factory,
  PerpTradeFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const facetCuts = [
  {
    facetAddress: config.Pools.PLP.facets.ownership,
    action: FacetCutAction.Add,
    functionSelectors: [
      OwnershipFacet__factory.createInterface().getSighash("owner()"),
      OwnershipFacet__factory.createInterface().getSighash(
        "transferOwnership(address)"
      ),
    ],
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  await (
    await poolDiamond.diamondCut(
      facetCuts,
      ethers.constants.AddressZero,
      "0x",
      { gasLimit: 100000000 }
    )
  ).wait();

  console.log(`Execute diamondCut for OwnershipFacet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Ownership"];
