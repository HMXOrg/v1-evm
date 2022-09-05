// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { MintableTokenInterface } from "../../../interfaces/MintableTokenInterface.sol";

interface GetterFacetInterface {
  function plp() external view returns (MintableTokenInterface);

  function lastAddLiquidityAtOf(address user) external view returns (uint256);

  function totalUsdDebt() external view returns (uint256);

  function getTargetValue(address token) external view returns (uint256);

  function getAddLiquidityFeeBps(address token, uint256 value)
    external
    view
    returns (uint256);

  function getAum(bool isUseMaxPrice) external view returns (uint256);

  function getAumE18(bool isUseMaxPrice) external view returns (uint256);

  function getRemoveLiquidityFeeBps(address token, uint256 value)
    external
    view
    returns (uint256);

  function getSwapFeeBps(
    address tokenIn,
    address tokenOut,
    uint256 usdDebt
  ) external view returns (uint256);

  function getNextFundingRate(address token) external view returns (uint256);
}
