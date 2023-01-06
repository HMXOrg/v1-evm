import { ethers, ContractFactory } from "ethers";
import { getConfig } from "./config";
import _ from "lodash";

export function getSelectors(contract: ContractFactory): Array<string> {
  const signatures = Object.keys(contract.interface.functions);
  const selectors = signatures.reduce((acc, val) => {
    acc.push(contract.interface.getSighash(val));
    return acc;
  }, [] as Array<string>);
  return selectors;
}

export function facetContractNameToAddress(contractName: string): string {
  const config = getConfig();
  const facetList = config.Pools.PLP.facets as any;
  contractName = contractName.replace("Facet", "");
  contractName = _.camelCase(contractName);
  const address = facetList[contractName];
  if (!address) {
    throw new Error(`Facet ${contractName} not found in config`);
  }
  return address;
}
