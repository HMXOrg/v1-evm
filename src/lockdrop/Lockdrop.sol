// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISimpleStrategy } from "./interfaces/ISimpleStrategy.sol";

contract Lockdrop is ReentrancyGuard, Ownable {
  // --- Libraries ---
  using SafeERC20 for IERC20;

  // --- Events ---
  event LogLockToken(
    address indexed account,
    address token,
    uint256 amount,
    uint256 lockPeriod
  );

  // --- Custom Errors ---
  error LockDrop_ZeroAddressNotAllowed();
  error LockDrop_InvalidStartLockTimestamp();
  error LockDrop_InvalidLockPeriod();
  error LockDrop_MismatchToken();
  error LockDrop_NotInDepositPeriod();
  error LockDrop_NotInWithdrawalPeriod();
  error Lockdrop_NoPLPToStake();

  // --- Structs ---

  struct LockdropState {
    uint256 lockdropTokenAmount;
    uint256 lockPeriod;
  }

  // --- States ---
  ISimpleStrategy public strategy;
  IERC20 public lockdropToken; // lockdrop token address
  uint256 public startLockTimestamp; // timestamp for starting lockdrop event
  uint256 public endLockTimestamp; // timestamp for deposit period after start lockdrop event
  uint256 public withdrawalTimestamp; // timestamp for withdraw period after start lockdrop event
  uint256 public totalAmount; // total amount of token
  uint256 public PLPAmount;
  mapping(address => LockdropState) public LockdropStates;

  // --- Modifiers ---
  /// @dev Only able to proceed during deposit period
  modifier onlyInDepositPeriod() {
    if (
      block.timestamp < startLockTimestamp ||
      block.timestamp > withdrawalTimestamp
    ) revert LockDrop_NotInDepositPeriod();
    _;
  }


  /// @dev Only able to proceed during withdrawal window
  modifier onlyInWithdrawalPeriod() {
    if (
      block.timestamp < withdrawalTimestamp ||
      block.timestamp > withdrawalTimestamp
    ) revert LockDrop_NotInWithdrawalPeriod();
    _;
  }

  constructor(address _lockdropToken, uint256 _startLockTimestamp, ISimpleStrategy _strategy) {
    if (_lockdropToken == address(0)) revert LockDrop_ZeroAddressNotAllowed();
    if (block.timestamp > _startLockTimestamp)
      revert LockDrop_InvalidStartLockTimestamp();

    strategy = _strategy;
    lockdropToken = IERC20(_lockdropToken);
    startLockTimestamp = _startLockTimestamp;
    endLockTimestamp = _startLockTimestamp + (7 days); // 7 days in second
    withdrawalTimestamp = _startLockTimestamp + (5 days); // 5 days in second
  }

  /// @dev User lock ERC20 Token
  /// @param _token Token address that user wants to lock
  /// @param _amount Number of token that user wants to lock
  /// @param _lockPeriod Number of second that user wants to lock
  function lockToken(
    address _token,
    uint256 _amount,
    uint256 _lockPeriod
  ) external onlyInDepositPeriod {
    if (_amount == 0) revert LockDrop_ZeroAddressNotAllowed();
    if (_lockPeriod < (7 days)) revert LockDrop_InvalidLockPeriod(); // Less than 1 week
    if (_lockPeriod > (7 days * 52)) revert LockDrop_InvalidLockPeriod(); // More than 52 weeks
    if (_token != address(lockdropToken)) revert LockDrop_MismatchToken(); // Mismatch token address

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    LockdropStates[msg.sender] = LockdropState({
      lockdropTokenAmount: _amount,
      lockPeriod: _lockPeriod
    });
    totalAmount += _amount;
    emit LogLockToken(msg.sender, _token, _amount, _lockPeriod);
  }

  function withdrawToken() external onlyInWithdrawalPeriod {

  }

  function mintPLP() external {
    PLPAmount = strategy.execute(totalAmount, address(lockdropToken));
    stakePLP();
  }

  function stakePLP() internal {
    if (PLPAmount == 0) revert Lockdrop_NoPLPToStake();

  }
}
