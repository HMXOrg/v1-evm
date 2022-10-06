import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber, ethers } from "ethers";
import * as fileHelpers from "../utils/file";
import * as assertHelpers from "../utils/assert";
import { parseBalanceMap } from "../utils/merkle/parse-balance-map";

type IBalanceFormat = { [account: string]: number | string };

interface IRow {
  address: string;
  amount: string;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const amountToDistribute = ethers.utils.parseUnits("4497.234393", 6);
  const distributionCsvPath = "./test.csv";
  const addressBalanceMap: IBalanceFormat = {};

  console.log("> Load csv from path:", distributionCsvPath);
  const rows = (await fileHelpers.readCsv(distributionCsvPath)) as Array<IRow>;
  console.log("> ✅ Done");

  console.log("> Find total amount");
  let totalAmount = rows.reduce((accum, curr) => {
    return accum.add(BigNumber.from(curr.amount));
  }, BigNumber.from(0));
  console.log("> ✅ Done");
  console.log("> Total Amount: ", ethers.utils.formatUnits(totalAmount, 6));

  console.log("> Build Merkle Tree with a new distribution");
  for (const row of rows) {
    addressBalanceMap[row.address] = amountToDistribute
      .mul(row.amount)
      .div(totalAmount)
      .toString();
  }
  const merkleTree = parseBalanceMap(addressBalanceMap);
  console.log("> ✅ Done");

  console.log(
    "> Check if total token in Merkle Tree is close to amount to distribute"
  );
  assertHelpers.assertBigNumberClosePercent(
    merkleTree.tokenTotal,
    amountToDistribute
  );
  console.log("> ✅ Done");

  console.log("> Write Merkle Tree");
  fileHelpers.writeJson("merkle.json", merkleTree);
  console.log("> ✅ Done");
};

export default func;
func.tags = ["BuildMerkleTree"];
