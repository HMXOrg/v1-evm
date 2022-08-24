// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILockdrop } from "./interfaces/ILockdrop.sol";
import { IAaveAToken } from "../interfaces/IAaveAToken.sol";
import { IAaveLendingPool } from "../interfaces/IAaveLendingPool.sol";
import { ILockdropGateway } from "./interfaces/ILockdropGateway.sol";

contract LockdropGateway is ILockdropGateway {
  using SafeERC20 for IERC20;

  enum TokenType {
    UninitializedToken,
    BaseToken,
    AToken,
    PairToken
  }

  struct LockdropInfo {
    TokenType tokenInType;
    address lockdrop;
    bytes metadata;
  }

  mapping(address => LockdropInfo) mapTokenLockdropInfo;

  error LockdropGateway_UnknownTokenType();
  error LockdropGateway_NotBaseToken();
  error LockdropGateway_NotAToken();
  error LockdropGateway_NotPairToken();
  error LockdropGateway_UninitializedToken();
  error LockdropGateway_NothingToDoWithPosition();

  // Claim All Reward Token
  // Pending for Lockdrop contract

  function claimAllStakingContractRewards(
    address[] memory lockdropList,
    address user
  ) external {
    uint256 length = lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(lockdropList[index]).claimAllReward(user);

      unchecked {
        ++index;
      }
    }
  }

  // Claim All P88 Token
  function claimAllP88(address[] memory lockdropList, address user) external {
    uint256 length = lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(lockdropList[index]).claimAllP88(user);

      unchecked {
        ++index;
      }
    }
  }

  // Withdraw All Deposit Token
  function withdrawAllLockedToken(address[] memory lockdropList, address user)
    external
  {
    uint256 length = lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(lockdropList[index]).withdrawAll(user);

      unchecked {
        ++index;
      }
    }
  }

  function lockToken(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) external {
    // Validate token, whether it is supported (whitelisted) by our contract or not
    TokenType tokenInType = mapTokenLockdropInfo[token].tokenInType;
    if (tokenInType == TokenType.UninitializedToken)
      revert LockdropGateway_UninitializedToken();

    // Transfer user's token
    IERC20(token).safeTransferFrom(msg.sender, address(this), lockAmount);

    // Call lock function correctly according to its type
    if (tokenInType == TokenType.BaseToken) {
      _handleLockBaseToken(token, lockAmount, lockPeriod);
      return;
    }
    if (tokenInType == TokenType.AToken) {
      _handleLockAToken(token, lockAmount, lockPeriod);
      return;
    }
    if (tokenInType == TokenType.PairToken) {
      _handleLockPairToken(token, lockAmount, lockPeriod);
      return;
    }

    revert LockdropGateway_UnknownTokenType();
  }

  function _handleLockBaseToken(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    if (mapTokenLockdropInfo[token].tokenInType != TokenType.BaseToken)
      revert LockdropGateway_NotBaseToken();

    _lockBaseTokenAtLockdrop(token, lockAmount, lockPeriod);
  }

  function _handleLockAToken(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    if (mapTokenLockdropInfo[token].tokenInType != TokenType.AToken)
      revert LockdropGateway_NotAToken();

    address baseToken = IAaveAToken(token).UNDERLYING_ASSET_ADDRESS();
    uint256 baseTokenAmount = IAaveLendingPool(IAaveAToken(token).POOL())
      .withdraw(baseToken, lockAmount, address(this));

    _handleLockBaseToken(baseToken, baseTokenAmount, lockPeriod);
  }

  function _handleLockPairToken(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    // TODO: implement
    revert();
  }

  function _lockBaseTokenAtLockdrop(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    address lockdrop = mapTokenLockdropInfo[token].lockdrop;
    (uint256 currentTokenAmount, ) = ILockdrop(
      mapTokenLockdropInfo[token].lockdrop
    ).lockdropStates(msg.sender);

    if (lockAmount > 0)
      IERC20(token).approve(mapTokenLockdropInfo[token].lockdrop, lockAmount);

    // TODO: change to lockTokenFor, addLockAmountFor, extendLockPeriodFor
    if (currentTokenAmount == 0) {
      // No lockdrop position yet, create a new one
      ILockdrop(lockdrop).lockToken(lockAmount, lockPeriod);
      return;
    } else {
      // Lockdrop position is existed, update with new param

      // Revert if input results in doing nothing
      if (lockAmount == 0 && lockPeriod == 0)
        revert LockdropGateway_NothingToDoWithPosition();

      if (lockAmount > 0) {
        ILockdrop(lockdrop).addLockAmount(lockAmount);
      }
      if (lockPeriod > 0) {
        ILockdrop(lockdrop).extendLockPeriod(lockAmount);
      }
      return;
    }
  }
}
