// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./BaseStaking.sol";
import "../tokens/DragonPoint.sol";

contract DragonStaking is BaseStaking {
  DragonPoint public dp;
  IRewarder public dragonPointRewarder;

  constructor(address dp_) {
    dp = DragonPoint(dp_);
  }

  function _afterWithdraw(
    address to,
    address, /*token*/
    uint256 /*amount*/
  ) internal override {
    _withdraw(to, address(dp), userTokenAmount[address(dp)][to]);

    dp.burn(to, dp.balanceOf(to));
    dragonPointRewarder.onWithdraw(to, 0);
  }

  function setDragonPointRewarder(address rewarder) external onlyOwner {
    dragonPointRewarder = IRewarder(rewarder);
  }
}
