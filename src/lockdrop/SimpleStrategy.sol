// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPool } from "../interfaces/IPool.sol";

contract SimpleStrategy {
  using SafeERC20 for IERC20;
  IPool public pool;

  constructor(IPool pool_) {
    pool = pool_;
  }

  function execute(uint256 tokenAmount, address tokenAddress)
    external
    returns (uint256)
  {
    // 1. Retrive Base Token
    IERC20(tokenAddress).safeTransferFrom(
      msg.sender,
      address(this),
      tokenAmount
    );

    // 2. Deposit to PLP Token to get amount of PLP
    return pool.addLiquidity(tokenAddress, tokenAmount, msg.sender, 0);
  }
}
