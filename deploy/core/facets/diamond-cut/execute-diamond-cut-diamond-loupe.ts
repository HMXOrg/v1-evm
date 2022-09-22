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
    facetAddress: config.Pools.PLP.facets.diamondLoupe,
    action: FacetCutAction.Add,
    functionSelectors: [
      DiamondLoupeFacet__factory.createInterface().getSighash("facets()"),
      DiamondLoupeFacet__factory.createInterface().getSighash(
        "facetAddress(bytes4)"
      ),
      DiamondLoupeFacet__factory.createInterface().getSighash(
        "facetAddresses()"
      ),
      DiamondLoupeFacet__factory.createInterface().getSighash(
        "facetFunctionSelectors(address)"
      ),
      DiamondLoupeFacet__factory.createInterface().getSighash(
        "supportsInterface(bytes4)"
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
    await poolDiamond.diamondCut(facetCuts, ethers.constants.AddressZero, "0x")
  ).wait();

  console.log(`Execute diamondCut for DiamondLoupeFacet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-DiamondLoupe"];
