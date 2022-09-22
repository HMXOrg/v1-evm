// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Constants {
  enum Exposure {
    LONG,
    SHORT
  }

  enum MinMax {
    MIN,
    MAX
  }

  enum LiquidationState {
    HEALTHY,
    SOFT_LIQUIDATE,
    LIQUIDATE
  }

  address internal constant LINKEDLIST_START = address(1);
  address internal constant LINKEDLIST_END = address(1);
  address internal constant LINKEDLIST_EMPTY = address(0);

  uint256 internal constant PRICE_PRECISION = 10**30;
  uint256 internal constant FUNDING_RATE_PRECISION = 1000000;
  uint256 internal constant ONE_USD = PRICE_PRECISION;
  uint256 internal constant BPS = 10000;
  uint256 internal constant USD_DECIMALS = 18;
}
