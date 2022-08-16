// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ChainlinkPriceFeedInterface } from "../interfaces/ChainlinkPriceFeedInterface.sol";
import { Constants } from "./Constants.sol";

contract PoolOracle is Constants, Ownable {
  using SafeCast for int256;

  error PoolOracle_BadArguments();
  error PoolOracle_PriceFeedNotAvailable();
  error PoolOracle_UnableFetchPrice();

  struct PriceFeedInfo {
    ChainlinkPriceFeedInterface priceFeed;
    uint8 decimals;
    uint64 spreadBps;
    bool isStrictStable;
  }
  mapping(address => PriceFeedInfo) public priceFeedInfo;
  uint80 public roundDepth;
  uint256 public maxStrictPriceDeviation;

  event SetMaxStrictPriceDeviation(
    uint256 prevMaxStrictPriceDeviation,
    uint256 newMaxStrictPriceDeviation
  );
  event SetPriceFeed(
    address token,
    PriceFeedInfo prevPriceFeedInfo,
    PriceFeedInfo newPriceFeedInfo
  );
  event SetRoundDepth(uint80 prevRoundDepth, uint80 newRoundDepth);

  constructor(uint80 _roundDepth) {
    if (_roundDepth == 0) revert PoolOracle_BadArguments();
    roundDepth = _roundDepth;
  }

  function _getPrice(address token, MinMax minOrMax)
    internal
    view
    returns (uint256)
  {
    // SLOAD
    PriceFeedInfo memory priceFeed = priceFeedInfo[token];
    if (address(priceFeed.priceFeed) == address(0))
      revert PoolOracle_PriceFeedNotAvailable();

    uint256 price = 0;
    int256 _priceCursor = 0;
    uint256 priceCursor = 0;
    uint80 latestRoundId = priceFeed.priceFeed.latestRound();

    for (uint80 i = 0; i < roundDepth; i++) {
      if (i >= latestRoundId) break;

      if (i == 0) {
        priceCursor = priceFeed.priceFeed.latestAnswer().toUint256();
      } else {
        (, _priceCursor, , , ) = priceFeed.priceFeed.getRoundData(
          latestRoundId - i
        );
        priceCursor = _priceCursor.toUint256();
      }

      if (price == 0) {
        price = priceCursor;
        continue;
      }

      if (minOrMax == MinMax.MAX && price < priceCursor) {
        price = priceCursor;
        continue;
      }

      if (minOrMax == MinMax.MIN && price > priceCursor) {
        price = priceCursor;
      }
    }

    if (price == 0) revert PoolOracle_UnableFetchPrice();

    price = (price * PRICE_PRECISION) / 10**priceFeed.decimals;

    // Handle strict stable price deviation.
    if (priceFeed.isStrictStable) {
      uint256 delta;
      unchecked {
        delta = price > ONE_USD ? price - ONE_USD : ONE_USD - price;
      }

      if (delta <= maxStrictPriceDeviation) return ONE_USD;

      if (minOrMax == MinMax.MAX && price > ONE_USD) return price;

      if (minOrMax == MinMax.MIN && price < ONE_USD) return price;

      return ONE_USD;
    }

    // Handle spreadBasisPoint
    if (minOrMax == MinMax.MAX)
      return (price * (BPS + priceFeed.spreadBps)) / BPS;

    return (price * (BPS - priceFeed.spreadBps)) / BPS;
  }

  function getMaxPrice(address token) external view returns (uint256) {
    return _getPrice(token, MinMax.MAX);
  }

  function getMinPrice(address token) external view returns (uint256) {
    return _getPrice(token, MinMax.MIN);
  }

  function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
    external
    onlyOwner
  {
    emit SetMaxStrictPriceDeviation(
      maxStrictPriceDeviation,
      _maxStrictPriceDeviation
    );
    maxStrictPriceDeviation = _maxStrictPriceDeviation;
  }

  function setPriceFeed(
    address[] calldata token,
    PriceFeedInfo[] calldata feedInfo
  ) external onlyOwner {
    if (token.length != feedInfo.length) revert PoolOracle_BadArguments();

    for (uint256 i = 0; i < token.length; ) {
      emit SetPriceFeed(token[i], priceFeedInfo[token[i]], feedInfo[i]);

      // Sanity check
      feedInfo[i].priceFeed.latestAnswer();

      priceFeedInfo[token[i]] = feedInfo[i];

      unchecked {
        ++i;
      }
    }
  }

  function setRoundDepth(uint80 _roundDepth) external onlyOwner {
    if (_roundDepth == 0) revert PoolOracle_BadArguments();

    emit SetRoundDepth(roundDepth, _roundDepth);
    roundDepth = _roundDepth;
  }
}
