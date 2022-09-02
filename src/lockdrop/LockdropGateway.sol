// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IAaveAToken } from "../interfaces/IAaveAToken.sol";
import { ICurveTokenV3Remover } from "../interfaces/ICurveTokenV3Remover.sol";
import { ICurveTokenV5Remover } from "../interfaces/ICurveTokenV5Remover.sol";
import { ICurveTokenV3 } from "../interfaces/ICurveTokenV3.sol";
import { IAaveLendingPool } from "../interfaces/IAaveLendingPool.sol";
import { IUniswapRouter } from "../interfaces/IUniswapRouter.sol";
import { IUniswapPair } from "../interfaces/IUniswapPair.sol";
import { ILockdrop } from "./interfaces/ILockdrop.sol";
import { ILockdropGateway } from "./interfaces/ILockdropGateway.sol";
import { IStaking } from "../staking/interfaces/IStaking.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockdropGateway is ILockdropGateway, Ownable {
  using SafeERC20 for IERC20;

  enum TokenType {
    UninitializedToken,
    BaseToken,
    AToken, // Aave
    LpPairToken, // SushiSwap, QuickSwap
    CurveV3Token, // Curve Aave LP Token (only support 3 underlycoins)
    CurveV5Token // ATriCrypto3 LP Token (only support 5 underlycoins)
  }

  struct LockdropInfo {
    TokenType tokenInType;
    address lockdrop;
    bytes metadata;
  }

  IERC20 public plpToken;
  IStaking public plpStaking;
  mapping(address => LockdropInfo) public mapTokenLockdropInfo;

  error LockdropGateway_UnknownTokenType();
  error LockdropGateway_NotBaseToken();
  error LockdropGateway_NotAToken();
  error LockdropGateway_NotPairToken();
  error LockdropGateway_NotCurveV3Token();
  error LockdropGateway_NotCurveV5Token();
  error LockdropGateway_UninitializedToken();
  error LockdropGateway_NothingToDoWithPosition();
  error LockdropGateway_NonBaseTokenZeroLockedAmount();

  constructor(IERC20 plpToken_, IStaking plpStaking_) {
    plpToken = plpToken_;
    plpStaking = plpStaking_;
  }

  function setBaseTokenLockdropInfo(address token, address lockdrop)
    external
    onlyOwner
  {
    _setLockdropInfo(token, TokenType.BaseToken, lockdrop, bytes(""));
  }

  function setATokenLockdropInfo(address token) external onlyOwner {
    _setLockdropInfo(token, TokenType.AToken, address(0), bytes(""));
  }

  function setLpPairTokenLockdropInfo(address token, address router)
    external
    onlyOwner
  {
    _setLockdropInfo(
      token,
      TokenType.LpPairToken,
      address(0),
      abi.encode(router)
    );
  }

  function setCurveV3TokenLockdropInfo(address token) external onlyOwner {
    _setLockdropInfo(token, TokenType.CurveV3Token, address(0), bytes(""));
  }

  function setCurveV5TokenLockdropInfo(
    address token,
    address zap,
    uint8 underlyTokenCount
  ) external onlyOwner {
    _setLockdropInfo(
      token,
      TokenType.CurveV5Token,
      address(0),
      abi.encode(zap, underlyTokenCount)
    );
  }

  function _setLockdropInfo(
    address token,
    TokenType tokenInType,
    address lockdrop,
    bytes memory metadata
  ) internal {
    mapTokenLockdropInfo[token] = LockdropInfo({
      tokenInType: tokenInType,
      lockdrop: lockdrop,
      metadata: metadata
    });
  }

  // Claim All Reward Token
  // Pending for Lockdrop contract
  function claimAllStakingContractRewards(
    address[] memory lockdropList,
    address user
  ) external {
    uint256 length = lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(lockdropList[index]).claimAllRewardsFor(user, user);
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
  function withdrawAllAndStakePLP(address[] memory lockdropList, address user)
    external
  {
    uint256 length = lockdropList.length;
    for (uint256 index = 0; index < length; ) {
      ILockdrop(lockdropList[index]).withdrawAll(user);

      unchecked {
        ++index;
      }
    }

    plpToken.approve(address(plpStaking), plpToken.balanceOf(address(this)));

    plpStaking.deposit(
      user,
      address(plpToken),
      plpToken.balanceOf(address(this))
    );
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

    // Amount check on non-base token
    if (lockAmount == 0) revert LockdropGateway_NonBaseTokenZeroLockedAmount();

    if (tokenInType == TokenType.AToken) {
      _handleLockAToken(token, lockAmount, lockPeriod);
      return;
    }
    if (tokenInType == TokenType.LpPairToken) {
      _handleLockLpPairToken(token, lockAmount, lockPeriod);
      return;
    }
    if (tokenInType == TokenType.CurveV3Token) {
      _handleLockCurveV3Token(token, lockAmount, lockPeriod);
      return;
    }
    if (tokenInType == TokenType.CurveV5Token) {
      _handleLockCurveV5Token(token, lockAmount, lockPeriod);
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

    if (lockAmount > 0)
      IERC20(token).approve(mapTokenLockdropInfo[token].lockdrop, lockAmount);

    _lockBaseTokenAtLockdrop(token, lockAmount, lockPeriod);
  }

  function _handleLockAToken(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    if (mapTokenLockdropInfo[token].tokenInType != TokenType.AToken)
      revert LockdropGateway_NotAToken();

    // Approve pool
    address pool = IAaveAToken(token).POOL();
    IERC20(token).approve(pool, lockAmount);

    // Convert AToken to base token
    address baseToken = IAaveAToken(token).UNDERLYING_ASSET_ADDRESS();
    uint256 baseTokenAmount = IAaveLendingPool(pool).withdraw(
      baseToken,
      lockAmount,
      address(this)
    );

    _handleLockBaseToken(baseToken, baseTokenAmount, lockPeriod);
  }

  function _handleLockLpPairToken(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    if (mapTokenLockdropInfo[token].tokenInType != TokenType.LpPairToken)
      revert LockdropGateway_NotPairToken();

    address baseToken0 = IUniswapPair(token).token0();
    address baseToken1 = IUniswapPair(token).token1();
    address router = abi.decode(
      mapTokenLockdropInfo[token].metadata,
      (address)
    );

    // Approve router
    IERC20(token).approve(router, lockAmount);

    (uint256 baseToken0Amount, uint256 baseToken1Amount) = IUniswapRouter(
      router
    ).removeLiquidity(
        baseToken0,
        baseToken1,
        lockAmount,
        0,
        0,
        address(this),
        block.timestamp
      );

    _handleLockBaseToken(baseToken0, baseToken0Amount, lockPeriod);
    _handleLockBaseToken(baseToken1, baseToken1Amount, lockPeriod);
  }

  function _handleLockCurveV3Token(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    if (mapTokenLockdropInfo[token].tokenInType != TokenType.CurveV3Token)
      revert LockdropGateway_NotCurveV3Token();

    address remover = ICurveTokenV3(token).minter();
    address[3] memory baseTokens = [
      ICurveTokenV3Remover(remover).underlying_coins(0),
      ICurveTokenV3Remover(remover).underlying_coins(1),
      ICurveTokenV3Remover(remover).underlying_coins(2)
    ];

    uint256[3] memory baseTokenAmountsBefore = [
      IERC20(baseTokens[0]).balanceOf(address(this)),
      IERC20(baseTokens[1]).balanceOf(address(this)),
      IERC20(baseTokens[2]).balanceOf(address(this))
    ];
    uint256[3] memory minAmounts;

    // approve
    IERC20(token).approve(remover, lockAmount);

    // remove
    ICurveTokenV3Remover(remover).remove_liquidity(
      lockAmount,
      minAmounts,
      true
    );

    // Find the actual receive amount, and then lock those tokens
    {
      uint256[3] memory baseTokenAmounts = [
        IERC20(baseTokens[0]).balanceOf(address(this)) -
          baseTokenAmountsBefore[0],
        IERC20(baseTokens[1]).balanceOf(address(this)) -
          baseTokenAmountsBefore[1],
        IERC20(baseTokens[2]).balanceOf(address(this)) -
          baseTokenAmountsBefore[2]
      ];
      _handleLockBaseToken(baseTokens[0], baseTokenAmounts[0], lockPeriod);
      _handleLockBaseToken(baseTokens[1], baseTokenAmounts[1], lockPeriod);
      _handleLockBaseToken(baseTokens[2], baseTokenAmounts[2], lockPeriod);
    }
  }

  function _handleLockCurveV5Token(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    if (mapTokenLockdropInfo[token].tokenInType != TokenType.CurveV5Token)
      revert LockdropGateway_NotCurveV5Token();

    address remover = abi.decode(
      mapTokenLockdropInfo[token].metadata,
      (address) // Zap address
    );

    address[5] memory baseTokens = [
      ICurveTokenV5Remover(remover).underlying_coins(0),
      ICurveTokenV5Remover(remover).underlying_coins(1),
      ICurveTokenV5Remover(remover).underlying_coins(2),
      ICurveTokenV5Remover(remover).underlying_coins(3),
      ICurveTokenV5Remover(remover).underlying_coins(4)
    ];

    uint256[5] memory baseTokenAmountsBefore = [
      IERC20(baseTokens[0]).balanceOf(address(this)),
      IERC20(baseTokens[1]).balanceOf(address(this)),
      IERC20(baseTokens[2]).balanceOf(address(this)),
      IERC20(baseTokens[3]).balanceOf(address(this)),
      IERC20(baseTokens[4]).balanceOf(address(this))
    ];
    uint256[5] memory minAmounts;

    // approve
    IERC20(token).approve(remover, lockAmount);

    // remove
    ICurveTokenV5Remover(remover).remove_liquidity(
      lockAmount,
      minAmounts,
      address(this)
    );

    // Find the actual receive amount, and then lock those tokens
    {
      uint256[5] memory baseTokenAmounts = [
        IERC20(baseTokens[0]).balanceOf(address(this)) -
          baseTokenAmountsBefore[0],
        IERC20(baseTokens[1]).balanceOf(address(this)) -
          baseTokenAmountsBefore[1],
        IERC20(baseTokens[2]).balanceOf(address(this)) -
          baseTokenAmountsBefore[2],
        IERC20(baseTokens[3]).balanceOf(address(this)) -
          baseTokenAmountsBefore[3],
        IERC20(baseTokens[4]).balanceOf(address(this)) -
          baseTokenAmountsBefore[4]
      ];

      _handleLockBaseToken(baseTokens[0], baseTokenAmounts[0], lockPeriod);
      _handleLockBaseToken(baseTokens[1], baseTokenAmounts[1], lockPeriod);
      _handleLockBaseToken(baseTokens[2], baseTokenAmounts[2], lockPeriod);
      _handleLockBaseToken(baseTokens[3], baseTokenAmounts[3], lockPeriod);
      _handleLockBaseToken(baseTokens[4], baseTokenAmounts[4], lockPeriod);
    }
  }

  function _lockBaseTokenAtLockdrop(
    address token,
    uint256 lockAmount,
    uint256 lockPeriod
  ) internal {
    address lockdrop = mapTokenLockdropInfo[token].lockdrop;
    (uint256 currentTokenAmount, , , ) = ILockdrop(
      mapTokenLockdropInfo[token].lockdrop
    ).lockdropStates(msg.sender);

    if (currentTokenAmount == 0) {
      // No lockdrop position yet, create a new one
      ILockdrop(lockdrop).lockTokenFor(lockAmount, lockPeriod, msg.sender);
      return;
    } else {
      // Lockdrop position is existed, update with new param
      if (lockAmount > 0) {
        ILockdrop(lockdrop).addLockAmountFor(lockAmount, msg.sender);
      }
      if (lockPeriod > 0) {
        ILockdrop(lockdrop).extendLockPeriodFor(lockPeriod, msg.sender);
      }
      return;
    }
  }
}
