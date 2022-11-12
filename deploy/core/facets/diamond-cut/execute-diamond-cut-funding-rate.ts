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
    facetAddress: config.Pools.PLP.facets.fundingRate,
    action: FacetCutAction.Add,
    functionSelectors: [
      FundingRateFacet__factory.createInterface().getSighash(
        "updateFundingRate(address, address)"
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

  console.log(`> Diamond cutting funding rate facet`);
  const tx = await poolDiamond.diamondCut(
    facetCuts,
    ethers.constants.AddressZero,
    "0x",
    {
      maxFeePerGas: ethers.utils.parseUnits("200", "gwei"),
      maxPriorityFeePerGas: ethers.utils.parseUnits("100", "gwei"),
    }
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> ✅ Diamond cut funding rate facet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-FundingRate"];
