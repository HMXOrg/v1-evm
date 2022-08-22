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
    address _lockdropToken,
    ILockdropStrategy _strategy,
    LockdropConfig _lockdropConfig
  ) {
    // Sanity check
    IERC20(_lockdropToken).balanceOf(address(this));
    if (block.timestamp > _lockdropConfig.startLockTimestamp())
      revert Lockdrop_InvalidStartLockTimestamp();

    strategy = _strategy;
    lockdropToken = IERC20(_lockdropToken);
    lockdropConfig = _lockdropConfig;
  }

  /// @dev Users can lock their ERC20 Token during the lockdrop period
  /// @param _amount Number of token that user wants to lock
  /// @param _lockPeriod Number of second that user wants to lock
  function lockToken(uint256 _amount, uint256 _lockPeriod)
    external
    onlyInLockdropPeriod
  {
    if (_amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (_lockPeriod < (7 days) || _lockPeriod > (7 days * 52))
      revert Lockdrop_InvalidLockPeriod(); // Less than 1 week or more than 52 weeks
    lockdropToken.safeTransferFrom(msg.sender, address(this), _amount);
    lockdropStates[msg.sender] = LockdropState({
      lockdropTokenAmount: _amount,
      lockPeriod: _lockPeriod
    });
    totalAmount += _amount;
    totalP88Weight += _amount * _lockPeriod;
    emit LogLockToken(msg.sender, _amount, _lockPeriod);
  }

  /// @dev Users can extend their lock period during the lockdrop period
  /// @param _newLockPeriod New number of second that user wants to lock
  function extendLockPeriod(uint256 _newLockPeriod)
    external
    onlyInLockdropPeriod
  {
    if (_newLockPeriod > (7 days * 52)) revert Lockdrop_InvalidLockPeriod(); // Less than 1 week or more than 52 weeks
    if (lockdropStates[msg.sender].lockdropTokenAmount == 0)
      revert Lockdrop_NoPosition();
    if (_newLockPeriod < lockdropStates[msg.sender].lockPeriod)
      revert Lockdrop_InvalidLockPeriod();
    totalP88Weight +=
      lockdropStates[msg.sender].lockdropTokenAmount *
      (_newLockPeriod - lockdropStates[msg.sender].lockPeriod);
    lockdropStates[msg.sender].lockPeriod = _newLockPeriod;
    emit LogNewLockPeriod(msg.sender, _newLockPeriod);
  }

  /// @dev Users can add more lock amount during the lockdrop period
  /// @param _amount Number of lock token that user want to add
  function addLockAmount(uint256 _amount) external onlyInLockdropPeriod {
    if (_amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (lockdropStates[msg.sender].lockdropTokenAmount == 0)
      revert Lockdrop_NoPosition();
    lockdropStates[msg.sender].lockdropTokenAmount += _amount;
    totalAmount += _amount;
    totalP88Weight += _amount * lockdropStates[msg.sender].lockPeriod;
    lockdropToken.safeTransferFrom(msg.sender, address(this), _amount);
    emit LogAddLockAmount(msg.sender, _amount);
  }

  /// @dev Users withdraw their ERC20 Token within lockdrop period and decaying period
  /// @param _amount Number of token that user wants to withdraw
  /// @param _user Address of the user that wants to withdraw
  function earlyWithdrawLockedToken(uint256 _amount, address _user)
    external
    onlyInLockdropPeriod
  {
    uint256 lockdropTokenAmount = lockdropStates[_user].lockdropTokenAmount;
    if (_amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (_amount > lockdropTokenAmount) revert Lockdrop_InsufficientBalance();
    if (
      block.timestamp >= lockdropConfig.withdrawalTimestamp() &&
      block.timestamp <= lockdropConfig.withdrawalTimestampDecay() &&
      _amount > (lockdropTokenAmount / 2)
    ) revert Lockdrop_InvalidAmount();
    if (
      block.timestamp >= lockdropConfig.withdrawalTimestampDecay() &&
      _amount >
      (((lockdropConfig.decayStartPercentage() *
        (lockdropConfig.endLockTimestamp() - block.timestamp)) /
        lockdropConfig.startTimeDecay()) * lockdropTokenAmount) /
        100
    ) revert Lockdrop_InvalidAmount();

    lockdropStates[_user].lockdropTokenAmount -= _amount;
    totalAmount -= _amount;
    totalP88Weight -= _amount * lockdropStates[_user].lockPeriod;
    if (lockdropStates[_user].lockdropTokenAmount == 0) {
      delete lockdropStates[_user];
    }

    lockdropToken.safeTransfer(msg.sender, _amount);
    emit LogWithdrawLockToken(
      _user,
      address(lockdropToken),
      _amount,
      lockdropStates[_user].lockdropTokenAmount
    );
  }

  /// @dev Users able to withdraw all their ERC20 Token after the end of the lockdrop period + their input lock period
  /// @param _user Address of the user that wants to withdraw
  function withdrawAll(address _user) external {
    if (
      block.timestamp <
      lockdropStates[_user].lockPeriod + lockdropConfig.endLockTimestamp()
    ) revert Lockdrop_InvalidWithdrawAllPeriod();
    uint256 userPLPTokenAmount = (lockdropStates[_user].lockdropTokenAmount *
      totalPLPAmount) / totalAmount;
    totalPLPAmount -= userPLPTokenAmount;
    lockdropConfig.plpStaking().withdraw(
      address(this),
      address(lockdropConfig.plpToken()),
      userPLPTokenAmount
    );
    lockdropConfig.plpToken().safeTransfer(_user, userPLPTokenAmount);
    delete lockdropStates[_user];
    emit LogWithdrawAll(_user, address(lockdropToken));
  }

  /// @dev Allocation feeder calls this function to transfer P88 to lockdrop
  /// @param _amount Number of P88 that feeder will feed
  function allocateP88(uint256 _amount) external onlyAfterLockdropPeriod {
    totalP88 += _amount;
    lockdropConfig.p88Token().safeTransferFrom(
      msg.sender,
      address(this),
      _amount
    );
  }

  /// @dev Users can claim their P88, this is a one time claim
  /// @param _user Address of the user that wants to claim P88
  function claimAllP88(address _user) external onlyAfterLockdropPeriod {
    if (totalP88Weight == 0) revert Lockdrop_ZeroP88WeightNotAllowed();
    if (claimP88[_user]) revert Lockdrop_P88AlreadyClaimed();

    lockdropConfig.p88Token().safeTransfer(
      _user,
      (totalP88 *
        lockdropStates[_user].lockdropTokenAmount *
        lockdropStates[_user].lockPeriod) / totalP88Weight
    );
    claimP88[_user] = true;
  }

  // /// @dev Users can claim all their reward
  // /// @param _user Address of the user that wants to claim the reward
  function claimAllReward(address _user) external onlyAfterLockdropPeriod {
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
