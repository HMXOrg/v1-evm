// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { LibPoolV1 } from "../libraries/LibPoolV1.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { PoolConfig } from "../../PoolConfig.sol";
import { PoolOracle } from "../../PoolOracle.sol";

import { AdminFacetInterface } from "../interfaces/AdminFacetInterface.sol";

contract AdminFacet is AdminFacetInterface {
  error AdminFacet_AllowTokensLengthMismatch();
  error AdminFacet_AllowTokensMismatch();
  error AdminFacet_Forbidden();
  error AdminFacet_TokenDecimalsMismatch();
  error AdminFacet_TokenWeightMismatch();
  error AdminFacet_TotalTokenWeightMismatch();

  address internal constant LINKEDLIST_START = address(1);
  address internal constant LINKEDLIST_END = address(1);
  address internal constant LINKEDLIST_EMPTY = address(0);

  event SetPoolConfig(PoolConfig prevPoolConfig, PoolConfig newPoolConfig);
  event SetPoolOracle(PoolOracle prevPoolOracle, PoolOracle newPoolOracle);
  event WithdrawFeeReserve(address token, address to, uint256 amount);

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  function setPoolConfig(PoolConfig newPoolConfig) external onlyOwner {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    // Check if critical configuration is valid on a new pool config.
    if (ds.config.totalTokenWeight() != newPoolConfig.totalTokenWeight())
      revert AdminFacet_TotalTokenWeightMismatch();
    if (
      ds.config.getAllowTokensLength() != newPoolConfig.getAllowTokensLength()
    ) revert AdminFacet_AllowTokensLengthMismatch();

    address oldConfigToken = ds.config.getNextAllowTokenOf(LINKEDLIST_START);
    address newConfigToken = ds.config.getNextAllowTokenOf(LINKEDLIST_START);

    while (oldConfigToken != LINKEDLIST_END) {
      if (oldConfigToken != newConfigToken)
        revert AdminFacet_AllowTokensMismatch();
      if (
        ds.config.getTokenDecimalsOf(oldConfigToken) !=
        newPoolConfig.getTokenDecimalsOf(oldConfigToken)
      ) revert AdminFacet_TokenDecimalsMismatch();
      if (
        ds.config.getTokenWeightOf(oldConfigToken) !=
        newPoolConfig.getTokenWeightOf(oldConfigToken)
      ) revert AdminFacet_TokenWeightMismatch();

      oldConfigToken = ds.config.getNextAllowTokenOf(oldConfigToken);
      newConfigToken = newPoolConfig.getNextAllowTokenOf(newConfigToken);
    }

    emit SetPoolConfig(ds.config, newPoolConfig);
    LibPoolV1.setPoolConfig(newPoolConfig);
  }

  function setPoolOracle(PoolOracle newPoolOracle) external onlyOwner {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    // Sanity check
    ds.oracle.roundDepth();

    emit SetPoolOracle(ds.oracle, newPoolOracle);
    ds.oracle = newPoolOracle;
  }

  function withdrawFeeReserve(
    address token,
    address to,
    uint256 amount
  ) external {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1
      .poolV1DiamondStorage();

    if (msg.sender != ds.config.treasury()) revert AdminFacet_Forbidden();

    ds.feeReserveOf[token] -= amount;
    LibPoolV1.pushTokens(token, to, amount);

    emit WithdrawFeeReserve(token, to, amount);
  }
}
