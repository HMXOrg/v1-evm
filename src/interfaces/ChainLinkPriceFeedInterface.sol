// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ChainLinkPriceFeedInterface {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestRound() external view returns (uint80);

  function getRoundData(uint80 roundId)
    external
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    );
}
