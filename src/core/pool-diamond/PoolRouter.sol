// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWNative } from "src/interfaces/IWNative.sol";
import { LiquidityFacetInterface } from "./interfaces/LiquidityFacetInterface.sol";

contract PoolRouter {
  using SafeERC20 for IERC20;

  IWNative public immutable WNATIVE;

  error PoolRouter_InsufficientOutputAmount(
    uint256 expectedAmount,
    uint256 actualAmount
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
  ) external {
    IERC20(token).safeTransferFrom(msg.sender, address(pool), amount);

    uint256 receivedAmount = LiquidityFacetInterface(pool).addLiquidity(
      msg.sender,
      token,
      receiver
    );

    if (receivedAmount < minLiquidity)
      revert PoolRouter_InsufficientOutputAmount(minLiquidity, receivedAmount);
  }

  function addLiquidityNative(
    address pool,
    address token,
    address receiver,
    uint256 minLiquidity
  ) external payable {
    WNATIVE.deposit{ value: msg.value }();
    IERC20(address(WNATIVE)).safeTransfer(address(pool), msg.value);

    uint256 receivedAmount = LiquidityFacetInterface(pool).addLiquidity(
      msg.sender,
      token,
      receiver
    );

    if (receivedAmount < minLiquidity)
      revert PoolRouter_InsufficientOutputAmount(minLiquidity, receivedAmount);
  }

  // function removeLiquidity(
  //   address pool,
  //   address tokenOut,
  //   uint256 liquidity,
  //   address receiver,
  //   uint256 minAmountOut
  // ) external {
  //   IERC20(pool.plp()).safeTransferFrom(msg.sender, address(pool), liquidity);

  //   uint256 receivedAmount = pool.removeLiquidity(
  //     msg.sender,
  //     tokenOut,
  //     receiver
  //   );

  //   if (receivedAmount < minAmountOut)
  //     revert PoolRouter_InsufficientOutputAmount(minAmountOut, receivedAmount);
  // }

  // function removeLiquidityNative(
  //   address pool,
  //   address tokenOut,
  //   uint256 liquidity,
  //   address receiver,
  //   uint256 minAmountOut
  // ) external payable {
  //   IERC20(pool.plp()).safeTransferFrom(msg.sender, address(pool), liquidity);

  //   uint256 receivedAmount = pool.removeLiquidity(
  //     msg.sender,
  //     tokenOut,
  //     address(this)
  //   );

  //   if (receivedAmount < minAmountOut)
  //     revert PoolRouter_InsufficientOutputAmount(minAmountOut, receivedAmount);

  //   WNATIVE.withdraw(receivedAmount);
  //   payable(receiver).transfer(receivedAmount);
  // }

  receive() external payable {
    assert(msg.sender == address(WNATIVE)); // only accept NATIVE via fallback from the WNATIVE contract
  }
}
