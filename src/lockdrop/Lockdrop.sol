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

contract Lockdrop is ReentrancyGuard, Ownable, ILockdrop {
  // --- Libraries ---
  using SafeERC20 for IERC20;

  // --- Events ---
  event LogLockToken(
    address indexed user,
    address token,
    uint256 amount,
    uint256 lockPeriod
  );

  event LogWithdrawLockToken(
    address indexed user,
    address token,
    uint256 amount,
    uint256 remainingAmount
  );

  event LogWithdrawAll(address indexed user, address token);

  // --- Custom Errors ---
  error Lockdrop_ZeroAmountNotAllowed();
  error Lockdrop_ZeroAddressNotAllowed();
  error Lockdrop_InvalidStartLockTimestamp();
  error Lockdrop_InvalidLockPeriod();
  error Lockdrop_MismatchToken();
  error Lockdrop_NotInDepositPeriod();
  error Lockdrop_NotInWithdrawalPeriod();
  error Lockdrop_InsufficientBalance();
  error Lockdrop_NotPassLockdropPeriod();
  error Lockdrop_InvalidWithdrawPeriod();

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

  mapping(address => LockdropState) public lockdropStates;

  // --- Modifiers ---
  /// @dev Only able to proceed during deposit period
  modifier onlyInDepositPeriod() {
    if (
      block.timestamp < lockdropConfig.startLockTimestamp() ||
      block.timestamp > lockdropConfig.withdrawalTimestamp()
    ) revert Lockdrop_NotInDepositPeriod();
    _;
  }

  /// @dev Only able to proceed during withdrawal period
  modifier onlyInWithdrawalPeriod() {
    if (
      block.timestamp < lockdropConfig.withdrawalTimestamp() ||
      block.timestamp > lockdropConfig.endLockTimestamp()
    ) revert Lockdrop_NotInWithdrawalPeriod();
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
    if (_lockdropToken == address(0)) revert Lockdrop_ZeroAddressNotAllowed();
    if (block.timestamp > _lockdropConfig.startLockTimestamp())
      revert Lockdrop_InvalidStartLockTimestamp();

    strategy = _strategy;
    lockdropToken = IERC20(_lockdropToken);
    lockdropConfig = _lockdropConfig;
  }

  /// @dev Users can lock their ERC20 Token, should be in a valid lock period (first 5 days)
  /// @param _token Token address that user wants to lock
  /// @param _amount Number of token that user wants to lock
  /// @param _lockPeriod Number of second that user wants to lock
  function lockToken(
    address _token,
    uint256 _amount,
    uint256 _lockPeriod
  ) external onlyInDepositPeriod {
    if (_amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (_token == address(0)) revert Lockdrop_ZeroAddressNotAllowed();
    if (_lockPeriod < (7 days)) revert Lockdrop_InvalidLockPeriod(); // Less than 1 week
    if (_lockPeriod > (7 days * 52)) revert Lockdrop_InvalidLockPeriod(); // More than 52 weeks
    if (_token != address(lockdropToken)) revert Lockdrop_MismatchToken(); // Mismatch token address

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    lockdropStates[msg.sender] = LockdropState({
      lockdropTokenAmount: _amount,
      lockPeriod: _lockPeriod
    });
    totalAmount += _amount;
    emit LogLockToken(msg.sender, _token, _amount, _lockPeriod);
  }

  /// @dev Users withdraw their ERC20 Token within lockdrop period, should be in a valid withdraw period (last 2 days)
  /// @param _amount Number of token that user wants to withdraw
  /// @param _user Address of the user that wants to withdraw
  function withdrawLockToken(uint256 _amount, address _user)
    external
    onlyInWithdrawalPeriod
  {
    if (_amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (_amount > lockdropStates[_user].lockdropTokenAmount)
      revert Lockdrop_InsufficientBalance();

    IERC20(address(lockdropToken)).safeTransfer(msg.sender, _amount);
    lockdropStates[_user].lockdropTokenAmount -= _amount;
    totalAmount -= _amount;
    if (lockdropStates[_user].lockdropTokenAmount == 0) {
      delete lockdropStates[_user];
    }
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
    ) revert Lockdrop_InvalidWithdrawPeriod();

    IERC20(address(lockdropToken)).safeTransfer(
      _user,
      lockdropStates[_user].lockdropTokenAmount
    );
    totalAmount -= lockdropStates[_user].lockdropTokenAmount;
    delete lockdropStates[_user];
    emit LogWithdrawAll(_user, address(lockdropToken));
  }

  function claimAllP88(address _user) external {}

  /// @dev Users can claim all their reward
  /// @param _user Address of the user that wants to cleam the reward
  function claimAllReward(address _user) external onlyAfterLockdropPeriod {
    lockdropConfig.plpStaking().harvest();
  }

  /// @dev PLP token is staked after the lockdrop period
  function stakePLP() external onlyAfterLockdropPeriod {
    lockdropConfig.plpStaking().deposit(
      address(this),
      lockdropConfig.plpTokenAddress(),
      strategy.execute(totalAmount, address(lockdropToken))
    );
  }
}
