// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { PoolOracle } from "../PoolOracle.sol";
import { PLP } from "../../tokens/PLP.sol";

import { LibReentrancyGuard } from "./libraries/LibReentrancyGuard.sol";
import { LibDiamond } from "./libraries/LibDiamond.sol";
import { LibPoolV1 } from "./libraries/LibPoolV1.sol";
import { DiamondCutInterface } from "./interfaces/DiamondCutInterface.sol";

/// @title Pool with ERC-2535 Diamond Standard.
/// Core logic of Diamond Standard is taken from https://github.com/mudgen/diamond-3-hardhat
contract PoolDiamond {
  constructor(address diamondCutFacet, PLP plp, PoolOracle poolOracle) payable {
    // Set contract owner
    LibDiamond.setContractOwner(msg.sender);

    // Set LibPool dependencies
    LibPoolV1.setPLP(plp);
    LibPoolV1.setPoolOracle(poolOracle);

    // Set LibReentrancyGuard
    LibReentrancyGuard.unlock();

    // Add the diamondCut external function from the diamondCutFacet
    DiamondCutInterface.FacetCut[]
      memory cut = new DiamondCutInterface.FacetCut[](1);
    bytes4[] memory functionSelectors = new bytes4[](1);
    functionSelectors[0] = DiamondCutInterface.diamondCut.selector;
    cut[0] = DiamondCutInterface.FacetCut({
      facetAddress: diamondCutFacet,
      action: DiamondCutInterface.FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    // get diamond storage
    assembly {
      ds.slot := position
    }
    // get facet from function selector
    address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
    require(facet != address(0), "Diamond: Function does not exist");
    // Execute external function from facet using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the facet
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  receive() external payable {}
}
