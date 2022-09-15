import { network } from "hardhat";
import MainnetConfig from "../../contracts.json";
import MumbaiConfig from "../../contracts.mumbai.json";

export function getConfig() {
  if (network.name === "polygon") {
    return MainnetConfig;
  }
  if (network.name === "mumbai") {
    return MumbaiConfig;
  }

  throw new Error("not found config");
}
