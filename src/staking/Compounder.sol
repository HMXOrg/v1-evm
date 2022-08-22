// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IStaking } from "./interfaces/IStaking.sol";
import { IRewarder } from "./interfaces/IRewarder.sol";

contract compounder is Ownable {
  using SafeERC20 for IERC20;

  address[] compoundTokens;
  mapping(address => bool) isCompoundTokens;
  address compoundPool;

  constructor(address compoundPool_, address[] memory compoundTokens_) {
    compoundPool = compoundPool_;
    addCompoundToken(compoundTokens_);
  }

  function addCompoundToken(address[] memory tokens) public onlyOwner {
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; ) {
      compoundTokens.push(tokens[i]);
      isCompoundTokens[tokens[i]] = true;

      unchecked {
        ++i;
      }
    }
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
      uint256 length = compoundTokens.length;
      for (uint256 i = 0; i < length; ) {
        uint256 amount = IERC20(compoundTokens[i]).balanceOf(address(this));
        if (isCompoundTokens[compoundTokens[i]]) {
          IStaking(compoundPool).deposit(msg.sender, compoundTokens[i], amount);
        } else {
          IERC20(compoundTokens[i]).safeTransfer(msg.sender, amount);
        }

        unchecked {
          ++i;
        }
      }
    }
  }
}
