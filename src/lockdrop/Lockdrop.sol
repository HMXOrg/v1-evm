// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ILockdropStrategy } from "./interfaces/ILockdropStrategy.sol";
import { IStaking } from "../staking/interfaces/IStaking.sol";
import { LockdropConfig } from "./LockdropConfig.sol";
import { ILockdrop } from "./interfaces/ILockdrop.sol";
import { P88 } from "../tokens/P88.sol";

contract Lockdrop is ReentrancyGuard, Ownable, ILockdrop {
  // --- Libraries ---
  using SafeERC20 for IERC20;

  // --- Events ---
  event LogLockToken(address indexed user, uint256 amount, uint256 lockPeriod);
  event LogAddLockAmount(address indexed user, uint256 amount);
  event LogNewLockPeriod(address indexed user, uint256 lockPeriod);
  event LogWithdrawLockToken(
    address indexed user,
    address token,
    uint256 amount,
    uint256 remainingAmount
  );
  event LogWithdrawAll(address indexed user, address token);

  // --- Custom Errors ---
  error Lockdrop_ZeroAmountNotAllowed();
  error Lockdrop_ZeroP88WeightNotAllowed();
  error Lockdrop_InvalidStartLockTimestamp();
  error Lockdrop_InvalidLockPeriod();
  error Lockdrop_InvalidWithdrawAllPeriod();
  error Lockdrop_NotInLockdropPeriod();
  error Lockdrop_InsufficientBalance();
  error Lockdrop_NotPassLockdropPeriod();
  error Lockdrop_P88AlreadyClaimed();
  error Lockdrop_NoPosition();
  error Lockdrop_InvalidAmount();

  // --- Structs ---
  struct LockdropState {
    uint256 lockdropTokenAmount;
    uint256 lockPeriod;
  }

  // --- States ---
  ILockdropStrategy public strategy;
  IERC20 public lockdropToken; // lockdrop token address
  LockdropConfig public lockdropConfig;
  uint256 public totalAmount; // total amount of token
  uint256 public totalP88Weight; // Sum of amount * lockPeriod
  uint256 public totalP88;
  uint256 public totalPLPAmount;

  mapping(address => LockdropState) public lockdropStates;
  mapping(address => bool) public claimP88;

  // --- Modifiers ---
  /// @dev Only in lockdrop period
  modifier onlyInLockdropPeriod() {
    if (block.timestamp > lockdropConfig.endLockTimestamp())
      revert Lockdrop_NotInLockdropPeriod();
    _;
  }

  /// @dev Only able to procees after lockdrop period
  modifier onlyAfterLockdropPeriod() {
    if (block.timestamp < lockdropConfig.endLockTimestamp())
      revert Lockdrop_NotPassLockdropPeriod();
    _;
  }

  constructor(
    address lockdropToken_,
    ILockdropStrategy strategy_,
    LockdropConfig lockdropConfig_
  ) {
    // Sanity check
    IERC20(lockdropToken_).balanceOf(address(this));
    if (block.timestamp > lockdropConfig_.startLockTimestamp())
      revert Lockdrop_InvalidStartLockTimestamp();

    strategy = strategy_;
    lockdropToken = IERC20(lockdropToken_);
    lockdropConfig = lockdropConfig_;
  }

  /// @dev Users can lock their ERC20 Token during the lockdrop period
  /// @param amount Number of token that user wants to lock
  /// @param lockPeriod Number of second that user wants to lock
  function lockToken(uint256 amount, uint256 lockPeriod)
    external
    onlyInLockdropPeriod
  {
    if (amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (lockPeriod < (7 days) || lockPeriod > (7 days * 52))
      revert Lockdrop_InvalidLockPeriod(); // Less than 1 week or more than 52 weeks
    lockdropToken.safeTransferFrom(msg.sender, address(this), amount);
    lockdropStates[msg.sender] = LockdropState({
      lockdropTokenAmount: amount,
      lockPeriod: lockPeriod
    });
    totalAmount += amount;
    totalP88Weight += amount * lockPeriod;
    emit LogLockToken(msg.sender, amount, lockPeriod);
  }

  /// @dev Users can extend their lock period during the lockdrop period
  /// @param newLockPeriod New number of second that user wants to lock
  function extendLockPeriod(uint256 newLockPeriod)
    external
    onlyInLockdropPeriod
  {
    if (newLockPeriod > (7 days * 52)) revert Lockdrop_InvalidLockPeriod(); // Less than 1 week or more than 52 weeks
    if (lockdropStates[msg.sender].lockdropTokenAmount == 0)
      revert Lockdrop_NoPosition();
    if (newLockPeriod < lockdropStates[msg.sender].lockPeriod)
      revert Lockdrop_InvalidLockPeriod();
    totalP88Weight +=
      lockdropStates[msg.sender].lockdropTokenAmount *
      (newLockPeriod - lockdropStates[msg.sender].lockPeriod);
    lockdropStates[msg.sender].lockPeriod = newLockPeriod;
    emit LogNewLockPeriod(msg.sender, newLockPeriod);
  }

  /// @dev Users can add more lock amount during the lockdrop period
  /// @param amount Number of lock token that user want to add
  function addLockAmount(uint256 amount) external onlyInLockdropPeriod {
    if (amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (lockdropStates[msg.sender].lockdropTokenAmount == 0)
      revert Lockdrop_NoPosition();
    lockdropStates[msg.sender].lockdropTokenAmount += amount;
    totalAmount += amount;
    totalP88Weight += amount * lockdropStates[msg.sender].lockPeriod;
    lockdropToken.safeTransferFrom(msg.sender, address(this), amount);
    emit LogAddLockAmount(msg.sender, amount);
  }

  /// @dev Users withdraw their ERC20 Token within lockdrop period and decaying period
  /// @param amount Number of token that user wants to withdraw
  /// @param user Address of the user that wants to withdraw
  function earlyWithdrawLockedToken(uint256 amount, address user)
    external
    onlyInLockdropPeriod
  {
    uint256 lockdropTokenAmount = lockdropStates[user].lockdropTokenAmount;
    if (amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (amount > lockdropTokenAmount) revert Lockdrop_InsufficientBalance();
    if (
      block.timestamp >= lockdropConfig.withdrawalTimestamp() &&
      block.timestamp <= lockdropConfig.withdrawalTimestampDecay() &&
      amount > (lockdropTokenAmount / 2)
    ) revert Lockdrop_InvalidAmount();
    if (
      block.timestamp >= lockdropConfig.withdrawalTimestampDecay() &&
      amount >
      (((lockdropConfig.decayStartPercentage() *
        (lockdropConfig.endLockTimestamp() - block.timestamp)) /
        lockdropConfig.startTimeDecay()) * lockdropTokenAmount) /
        100
    ) revert Lockdrop_InvalidAmount();

    lockdropStates[user].lockdropTokenAmount -= amount;
    totalAmount -= amount;
    totalP88Weight -= amount * lockdropStates[user].lockPeriod;
    if (lockdropStates[user].lockdropTokenAmount == 0) {
      delete lockdropStates[user];
    }

    lockdropToken.safeTransfer(msg.sender, amount);
    emit LogWithdrawLockToken(
      user,
      address(lockdropToken),
      amount,
      lockdropStates[user].lockdropTokenAmount
    );
  }

  /// @dev Users able to withdraw all their ERC20 Token after the end of the lockdrop period + their input lock period
  /// @param user Address of the user that wants to withdraw
  function withdrawAll(address user) external {
    if (
      block.timestamp <
      lockdropStates[user].lockPeriod + lockdropConfig.endLockTimestamp()
    ) revert Lockdrop_InvalidWithdrawAllPeriod();
    uint256 userPLPTokenAmount = (lockdropStates[user].lockdropTokenAmount *
      totalPLPAmount) / totalAmount;
    totalPLPAmount -= userPLPTokenAmount;
    lockdropConfig.plpStaking().withdraw(
      address(this),
      address(lockdropConfig.plpToken()),
      userPLPTokenAmount
    );
    lockdropConfig.plpToken().safeTransfer(user, userPLPTokenAmount);
    delete lockdropStates[user];
    emit LogWithdrawAll(user, address(lockdropToken));
  }

  /// @dev Allocation feeder calls this function to transfer P88 to lockdrop
  /// @param amount Number of P88 that feeder will feed
  function allocateP88(uint256 amount) external onlyAfterLockdropPeriod {
    totalP88 += amount;
    lockdropConfig.p88Token().safeTransferFrom(
      msg.sender,
      address(this),
      amount
    );
  }

  /// @dev Users can claim their P88, this is a one time claim
  /// @param user Address of the user that wants to claim P88
  function claimAllP88(address user) external onlyAfterLockdropPeriod {
    if (totalP88Weight == 0) revert Lockdrop_ZeroP88WeightNotAllowed();
    if (claimP88[user]) revert Lockdrop_P88AlreadyClaimed();

    lockdropConfig.p88Token().safeTransfer(
      user,
      (totalP88 *
        lockdropStates[user].lockdropTokenAmount *
        lockdropStates[user].lockPeriod) / totalP88Weight
    );
    claimP88[user] = true;
  }

  // /// @dev Users can claim all their reward
  // /// @param user Address of the user that wants to claim the reward
  function claimAllReward(address user) external onlyAfterLockdropPeriod {
    //   lockdropConfig.plpStaking().harvest();
  }

  /// @dev PLP token is staked after the lockdrop period
  function stakePLP() external onlyAfterLockdropPeriod {
    totalPLPAmount = strategy.execute(totalAmount, address(lockdropToken));
    lockdropConfig.plpStaking().deposit(
      address(this),
      address(lockdropConfig.plpToken()),
      totalPLPAmount
    );
  }
}
