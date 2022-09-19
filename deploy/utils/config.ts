import { network } from "hardhat";
import * as fs from "fs";
import MainnetConfig from "../../contracts.json";
import TenderlyConfig from "../../contracts.tenderly.json";
import MumbaiConfig from "../../contracts.mumbai.json";

export function getConfig() {
  if (network.name === "polygon") {
    return MainnetConfig;
  }
  if (network.name === "tenderly") {
    return TenderlyConfig;
  }
  if (network.name === "mumbai") {
    return MumbaiConfig;
  }

  throw new Error("not found config");
}

export function writeConfigFile(config: any) {
  let filePath;
  switch (network.name) {
    case "polygon":
      filePath = "contracts.json";
      break;
    case "tenderly":
      filePath = "contracts.tenderly.json";
      break;
    case "mumbai":
      filePath = "contracts.mumbai.json";
      break;
    default:
      throw Error("Unsupported network");
  }
  console.log(`>> Writing ${filePath}`);
  fs.writeFileSync(filePath, JSON.stringify(config, null, 2));
  console.log("✅ Done");
}
