// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IPool } from "../../interfaces/IPool.sol";
import { console } from "../utils/console.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockPool is IPool {
  using SafeERC20 for IERC20;

  function addLiquidity(
    address token,
    uint256 amount,
    address receiver,
    uint256 minLiquidity
  ) public returns (uint256) {
    return amount * 2;
  }

  function swap(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    address receiver
  ) external returns (uint256) {
    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

    MockErc20(tokenOut).mint(address(this), 1 ether);
    MockErc20(tokenOut).approve(address(this), 1 ether);

    IERC20(tokenOut).transfer(receiver, 1 ether);

    return 20;
  }
}
