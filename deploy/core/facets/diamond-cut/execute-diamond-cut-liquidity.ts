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
    facetAddress: config.Pools.PLP.facets.liquidity,
    action: FacetCutAction.Add,
    functionSelectors: [
      LiquidityFacetInterface__factory.createInterface().getSighash(
        "addLiquidity(address,address,address)"
      ),
      LiquidityFacetInterface__factory.createInterface().getSighash(
        "removeLiquidity(address,address,address)"
      ),
      LiquidityFacetInterface__factory.createInterface().getSighash(
        "swap(address,address,uint256,address)"
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

  console.log(`Execute diamondCut for LiquidityFacet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Liquidity"];
