// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./BaseStaking.sol";
import "../tokens/DragonPoint.sol";

contract DragonStaking is BaseStaking {
  DragonPoint public dp;

  constructor(address dp_) {
    dp = DragonPoint(dp_);
  }

  function _afterWithdraw(
    address to,
    address, /*token*/
    uint256 /*amount*/
  ) internal override {
    dp.burn(to, dp.balanceOf(to));
    dp.burn(address(this), userTokenAmount[address(dp)][to]);
    userTokenAmount[address(dp)][to] = 0;
  }
}