// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IStaking } from "./interfaces/IStaking.sol";
import { IRewarder } from "./interfaces/IRewarder.sol";

contract Compounder is Ownable {
  using SafeERC20 for IERC20;

  address[] tokens;
  mapping(address => bool) isCompoundTokens;
  address compoundPool;

  constructor(
    address compoundPool_,
    address[] memory compoundTokens_,
    bool[] memory isCompoundTokens_
  ) {
    compoundPool = compoundPool_;
    addToken(compoundTokens_, isCompoundTokens_);
  }

  function addToken(
    address[] memory newTokens,
    bool[] memory newIsCompoundTokens
  ) public onlyOwner {
    uint256 length = newTokens.length;
    for (uint256 i = 0; i < length; ) {
      tokens.push(newTokens[i]);
      isCompoundTokens[tokens[i]] = newIsCompoundTokens[i];

      if (newIsCompoundTokens[i])
        IERC20(newTokens[i]).approve(compoundPool, type(uint256).max);

      unchecked {
        ++i;
      }
    }
  }

  function setCompoundToken(address token, bool isCompoundToken)
    public
    onlyOwner
  {
    isCompoundTokens[token] = isCompoundToken;
  }

  function claimAll(address[] memory pools, address[][] memory rewarders)
    public
  {
    uint256 length = pools.length;
    for (uint256 i = 0; i < length; ) {
      IStaking(pools[i]).harvest(rewarders[i]);

      unchecked {
        ++i;
      }
    }
  }

  function compound(address[] memory pools, address[][] memory rewarders)
    public
  {
    {
      uint256 length = pools.length;
      for (uint256 i = 0; i < length; ) {
        IStaking(pools[i]).harvestToCompounder(msg.sender, rewarders[i]);

        unchecked {
          ++i;
        }
      }
    }

    {
      uint256 length = tokens.length;
      for (uint256 i = 0; i < length; ) {
        uint256 amount = IERC20(tokens[i]).balanceOf(address(this));
        if (isCompoundTokens[tokens[i]]) {
          IStaking(compoundPool).deposit(msg.sender, tokens[i], amount);
        } else {
          IERC20(tokens[i]).safeTransfer(msg.sender, amount);
        }

        unchecked {
          ++i;
        }
      }

      payable(msg.sender).transfer(address(this).balance);
    }
  }

  receive() external payable {}
}
