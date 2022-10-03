// import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { DeployFunction } from "hardhat-deploy/types";
// import { ethers } from "hardhat";
// import {
//   ERC20__factory,
//   GetterFacet__factory,
//   PLPStaking__factory,
//   PoolOracle__factory,
// } from "../../typechain";
// import { getConfig } from "../utils/config";

// const config = getConfig();
// const BigNumber = ethers.BigNumber;
// const collateralToken = config.Tokens.WBTC;
// const indexToken = config.Tokens.WBTC;
// const isLong = true;

// const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
//   const deployer = (await ethers.getSigners())[0];
//   const pool = GetterFacet__factory.connect(
//     config.Pools.PLP.poolDiamond,
//     deployer
//   );
//   const poolOracle = PoolOracle__factory.connect(
//     config.Pools.PLP.oracle,
//     deployer
//   );
//   const liquidity = await pool.liquidityOf(collateralToken);
//   const reserved = await pool.reservedOf(collateralToken);
//   const available = liquidity.sub(reserved);
//   const sumFundingRateOf = await pool.sumFundingRateOf(collateralToken);
//   const nextFundingRate = await pool.getNextFundingRate(collateralToken);
//   let delta = null;
//   try {
//     delta = await pool.getPositionDelta(
//       "0x0578C797798Ae89b688Cd5676348344d7d0EC35E",
//       0,
//       collateralToken,
//       indexToken,
//       isLong
//     );
//   } catch (e) {}

//   console.log("liquidity", liquidity);
//   console.log("reserved", reserved);
//   console.log("available", available);
//   console.log("sumFundingRateOf", sumFundingRateOf);
//   console.log("nextFundingRate", nextFundingRate);
//   console.log("delta", delta);

//   const minPriceCollateral = await poolOracle.getMinPrice(collateralToken);
//   const maxPriceCollateral = await poolOracle.getMaxPrice(collateralToken);
//   const minPriceIndex = await poolOracle.getMinPrice(indexToken);
//   const maxPriceIndex = await poolOracle.getMaxPrice(indexToken);
//   console.log("Collateral:minPrice", minPriceCollateral);
//   console.log("Collateral:maxPrice", maxPriceCollateral);
//   console.log("Index:minPrice", minPriceIndex);
//   console.log("Index:maxPrice", maxPriceIndex);

//   const position = await pool.getPosition(
//     "0x0578C797798Ae89b688Cd5676348344d7d0EC35E",
//     collateralToken,
//     indexToken,
//     isLong
//   );
//   console.log("position", position);

//   console.log("totalUsdDebt", await pool.totalUsdDebt());
// };

// export default func;
// func.tags = ["ReadData"];
