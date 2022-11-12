import { ethers, utils } from "ethers";
import axios from "axios";

interface BlockScanGasData {
  SafeGasPrice: string;
  ProposeGasPrice: string;
  FastGasPrice: string;
  suggestBaseFee: string;
}

/// Get the rapid gas setup for EIP1559 transaction
/// This will bump whatever node returns by 50%
export async function eip1559rapidGas() {
  const gasStationResponse = await axios.get(
    "https://gpoly.blockscan.com/gasapi.ashx?apikey=key&method=gasoracle"
  );
  const gasData = gasStationResponse.data.result as BlockScanGasData;
  const baseFee = ethers.utils.parseUnits(gasData.suggestBaseFee, "gwei");
  const rapidGas = ethers.utils.parseUnits(gasData.FastGasPrice, "gwei");

  return {
    type: 2,
    maxFeePerGas: rapidGas.mul(2),
    maxPriorityFeePerGas: rapidGas.mul(2).sub(baseFee),
  };
}
