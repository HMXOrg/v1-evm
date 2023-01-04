import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DiamondCutFacet__factory,
  DiamondCutInterface,
  DiamondLoupeFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";
import {
  facetContractNameToAddress,
  getSelectors,
} from "../../../utils/diamond";
import * as readlineSync from "readline-sync";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const FACET = "GetterFacet";
  const INITIALIZER_ADDRESS = ethers.constants.AddressZero;

  const deployer = (await ethers.getSigners())[0];

  const diamondLoupeFacet = DiamondLoupeFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  const diamondCutFacet = DiamondCutFacet__factory.connect(
    config.Pools.PLP.poolDiamond,
    deployer
  );

  console.log(`> Diamond cutting ${FACET}`);

  // Build the facetCuts array
  const contractFactory = await ethers.getContractFactory(FACET);
  const facetAddress = facetContractNameToAddress(FACET);
  const existedFacetCuts = (await diamondLoupeFacet.facets())
    .map((each) => each.functionSelectors)
    .reduce((result, array) => result.concat(array), []);
  const facetCuts: Array<DiamondCutInterface.FacetCutStruct> = [];
  const replaceSelectors: Array<string> = [];
  const addSelectors: Array<string> = [];
  const functionSelectors = getSelectors(contractFactory);
  // Loop through each selector to find out if it needs to replace or add
  for (const selector of functionSelectors) {
    if (existedFacetCuts.includes(selector)) {
      replaceSelectors.push(selector);
    } else {
      addSelectors.push(selector);
    }
  }
  // Put the replaceSelectors and addSelectors into facetCuts
  if (replaceSelectors.length > 0) {
    facetCuts.push({
      facetAddress,
      action: FacetCutAction.Replace,
      functionSelectors: replaceSelectors,
    });
  }
  if (addSelectors.length > 0) {
    facetCuts.push({
      facetAddress,
      action: FacetCutAction.Add,
      functionSelectors: addSelectors,
    });
  }

  console.log(`> Found ${replaceSelectors.length} selectors to replace`);
  console.log(`> Methods to replace:`);
  console.table(
    replaceSelectors.map((each) => {
      return {
        functionName: contractFactory.interface.getFunction(each).name,
        selector: each,
      };
    })
  );
  console.log(`> Found ${addSelectors.length} selectors to add`);
  console.log(`> Methods to add:`);
  console.table(
    addSelectors.map((each) => {
      return {
        functionName: contractFactory.interface.getFunction(each).name,
        selector: each,
      };
    })
  );

  // Ask for confirmation
  const confirmExecuteDiamondCut = readlineSync.question("Confirm? (y/n): ");
  switch (confirmExecuteDiamondCut.toLowerCase()) {
    case "y":
      break;
    case "n":
      console.log("Aborting");
      return;
    default:
      console.log("Invalid input");
      return;
  }

  console.log("> Executing diamond cut");
  const tx = await diamondCutFacet.diamondCut(
    facetCuts,
    INITIALIZER_ADDRESS,
    "0x"
  );
  console.log(`> Tx is submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined`);
  await tx.wait(3);
  console.log(`> Tx is mined`);
};

export default func;
func.tags = ["ExecuteDiamondCut"];
