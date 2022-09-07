// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig } from "../../PoolConfig.sol";
import { PoolOracle } from "../../PoolOracle.sol";

interface AdminFacetInterface {
  function setPoolConfig(PoolConfig newPoolConfig) external;

  function setPoolOracle(PoolOracle newPoolOracle) external;

  function withdrawFeeReserve(
    address token,
    address to,
    uint256 amount
  ) external;
}
