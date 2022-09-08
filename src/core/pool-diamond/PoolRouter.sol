// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWNative } from "src/interfaces/IWNative.sol";
import { LiquidityFacetInterface } from "./interfaces/LiquidityFacetInterface.sol";
import { GetterFacetInterface } from "./interfaces/GetterFacetInterface.sol";
import { PerpTradeFacetInterface } from "src/core/pool-diamond/interfaces/PerpTradeFacetInterface.sol";
import { PoolOracle } from "src/core/PoolOracle.sol";

contract PoolRouter {
  using SafeERC20 for IERC20;

  IWNative public immutable WNATIVE;

  error PoolRouter_InsufficientOutputAmount(
    uint256 expectedAmount,
    uint256 actualAmount
  );
  error PoolRouter_MarkPriceTooHigh(
    uint256 acceptablePrice,
    uint256 actualPrice
  );
  error PoolRouter_MarkPriceTooLow(
    uint256 acceptablePrice,
    uint256 actualPrice
  );

  constructor(address wNative_) {
    WNATIVE = IWNative(wNative_);
  }

  function addLiquidity(
    address pool,
    address token,
    uint256 amount,
    address receiver,
    uint256 minLiquidity
  ) external returns (uint256) {
    IERC20(token).safeTransferFrom(msg.sender, address(pool), amount);

    uint256 receivedAmount = LiquidityFacetInterface(pool).addLiquidity(
      msg.sender,
      token,
      receiver
    );

    if (receivedAmount < minLiquidity)
      revert PoolRouter_InsufficientOutputAmount(minLiquidity, receivedAmount);
    return receivedAmount;
  }

  function addLiquidityNative(
    address pool,
    address token,
    address receiver,
    uint256 minLiquidity
  ) external payable returns (uint256) {
    WNATIVE.deposit{ value: msg.value }();
    IERC20(address(WNATIVE)).safeTransfer(address(pool), msg.value);

    uint256 receivedAmount = LiquidityFacetInterface(pool).addLiquidity(
      msg.sender,
      token,
      receiver
    );

    if (receivedAmount < minLiquidity)
      revert PoolRouter_InsufficientOutputAmount(minLiquidity, receivedAmount);
    return receivedAmount;
  }

  function removeLiquidity(
    address pool,
    address tokenOut,
    uint256 liquidity,
    address receiver,
    uint256 minAmountOut
  ) external returns (uint256) {
    IERC20(GetterFacetInterface(pool).plp()).safeTransferFrom(
      msg.sender,
      address(pool),
      liquidity
    );

    uint256 receivedAmount = LiquidityFacetInterface(pool).removeLiquidity(
      msg.sender,
      tokenOut,
      receiver
    );

    if (receivedAmount < minAmountOut)
      revert PoolRouter_InsufficientOutputAmount(minAmountOut, receivedAmount);
    return receivedAmount;
  }

  function removeLiquidityNative(
    address pool,
    address tokenOut,
    uint256 liquidity,
    address receiver,
    uint256 minAmountOut
  ) external payable returns (uint256) {
    IERC20(GetterFacetInterface(pool).plp()).safeTransferFrom(
      msg.sender,
      address(pool),
      liquidity
    );

    uint256 receivedAmount = LiquidityFacetInterface(pool).removeLiquidity(
      msg.sender,
      tokenOut,
      address(this)
    );

    if (receivedAmount < minAmountOut)
      revert PoolRouter_InsufficientOutputAmount(minAmountOut, receivedAmount);

    WNATIVE.withdraw(receivedAmount);
    payable(receiver).transfer(receivedAmount);
    return receivedAmount;
  }

  function increasePosition(
    address pool,
    uint256 subAccountId,
    address collateralToken,
    uint256 collateralTokenAmount,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 acceptablePrice
  ) external {
    PoolOracle oracle = PoolOracle(GetterFacetInterface(pool).oracle());
    if (isLong) {
      uint256 actualPrice = oracle.getMaxPrice(indexToken);
      if (!(actualPrice <= acceptablePrice))
        revert PoolRouter_MarkPriceTooHigh(acceptablePrice, actualPrice);
    } else {
      uint256 actualPrice = oracle.getMinPrice(indexToken);
      if (!(actualPrice >= acceptablePrice))
        revert PoolRouter_MarkPriceTooLow(acceptablePrice, actualPrice);
    }

    IERC20(collateralToken).safeTransferFrom(
      msg.sender,
      pool,
      collateralTokenAmount
    );

    PerpTradeFacetInterface(pool).increasePosition(
      msg.sender,
      subAccountId,
      collateralToken,
      indexToken,
      sizeDelta,
      isLong
    );
  }

  function increasePositionNative(
    address pool,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 acceptablePrice
  ) external payable {
    PoolOracle oracle = PoolOracle(GetterFacetInterface(pool).oracle());
    if (isLong) {
      uint256 actualPrice = oracle.getMaxPrice(indexToken);
      if (!(actualPrice <= acceptablePrice))
        revert PoolRouter_MarkPriceTooHigh(acceptablePrice, actualPrice);
    } else {
      uint256 actualPrice = oracle.getMinPrice(indexToken);
      if (!(actualPrice >= acceptablePrice))
        revert PoolRouter_MarkPriceTooLow(acceptablePrice, actualPrice);
    }

    WNATIVE.deposit{ value: msg.value }();
    IERC20(address(WNATIVE)).safeTransfer(pool, msg.value);

    PerpTradeFacetInterface(pool).increasePosition(
      msg.sender,
      subAccountId,
      collateralToken,
      indexToken,
      sizeDelta,
      isLong
    );
  }

  function decreasePosition(
    address pool,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    address receiver,
    uint256 acceptablePrice,
    uint256 minAmountOut
  ) external {
    PoolOracle oracle = PoolOracle(GetterFacetInterface(pool).oracle());
    if (isLong) {
      uint256 actualPrice = oracle.getMinPrice(indexToken);
      if (!(actualPrice >= acceptablePrice))
        revert PoolRouter_MarkPriceTooLow(acceptablePrice, actualPrice);
    } else {
      uint256 actualPrice = oracle.getMaxPrice(indexToken);
      if (!(actualPrice <= acceptablePrice))
        revert PoolRouter_MarkPriceTooHigh(acceptablePrice, actualPrice);
    }

    uint256 amountOut = PerpTradeFacetInterface(pool).decreasePosition(
      msg.sender,
      subAccountId,
      collateralToken,
      indexToken,
      collateralDelta,
      sizeDelta,
      isLong,
      receiver
    );

    if (amountOut < minAmountOut)
      revert PoolRouter_InsufficientOutputAmount(minAmountOut, amountOut);
  }

  function decreasePositionNative(
    address pool,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    address receiver,
    uint256 acceptablePrice,
    uint256 minAmountOut
  ) external {
    PoolOracle oracle = PoolOracle(GetterFacetInterface(pool).oracle());
    if (isLong) {
      uint256 actualPrice = oracle.getMinPrice(indexToken);
      if (!(actualPrice >= acceptablePrice))
        revert PoolRouter_MarkPriceTooLow(acceptablePrice, actualPrice);
    } else {
      uint256 actualPrice = oracle.getMaxPrice(indexToken);
      if (!(actualPrice <= acceptablePrice))
        revert PoolRouter_MarkPriceTooHigh(acceptablePrice, actualPrice);
    }

    uint256 amountOut = PerpTradeFacetInterface(pool).decreasePosition(
      msg.sender,
      subAccountId,
      collateralToken,
      indexToken,
      collateralDelta,
      sizeDelta,
      isLong,
      receiver
    );

    if (amountOut < minAmountOut)
      revert PoolRouter_InsufficientOutputAmount(minAmountOut, amountOut);

    WNATIVE.withdraw(amountOut);
    payable(receiver).transfer(amountOut);
  }

  receive() external payable {
    assert(msg.sender == address(WNATIVE)); // only accept NATIVE via fallback from the WNATIVE contract
  }
}
