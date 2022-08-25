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
  event LogExtendLockPeriod(address indexed user, uint256 lockPeriod);
  event LogWithdrawLockToken(
    address indexed user,
    address token,
    uint256 amount,
    uint256 remainingAmount
  );
  event LogWithdrawAll(address indexed user, address token);
  event LogAllocateP88(uint256 amount);
  event LogClaimAllP88(address indexed user, uint256 p88Amount);
  event LogStakePLP(uint256 plpTokenAmount);

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
  error Lockdrop_UserAlreadyLocked();
  error Lockdrop_ZeroTotalPLPAmount();
  error Lockdrop_NotAllocationFeeder();
  error Lockdrop_ZeroTotalP88NotAllowed();
  error Lockdrop_AlreadyAllocateP88();
  error Lockdrop_PLPAlreadyStaked();
  error Lockdrop_NotGateway();

  // --- Structs ---
  struct LockdropState {
    uint256 lockdropTokenAmount;
    uint256 lockPeriod;
    bool p88Claimed;
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

  // --- Modifiers ---
  /// @dev Only in lockdrop period
  modifier onlyInLockdropPeriod() {
    if (
      block.timestamp < lockdropConfig.startLockTimestamp() ||
      block.timestamp > lockdropConfig.endLockTimestamp()
    ) revert Lockdrop_NotInLockdropPeriod();
    _;
  }

  /// @dev Only able to procees after lockdrop period
  modifier onlyAfterLockdropPeriod() {
    if (block.timestamp < lockdropConfig.endLockTimestamp())
      revert Lockdrop_NotPassLockdropPeriod();
    _;
  }

  /// @dev ACL Gateway
   modifier onlyGateway() {
    if (msg.sender != lockdropConfig.gatewayAddress()) revert Lockdrop_NotGateway();
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

  function _lockTokenFor(
    uint256 amount,
    uint256 lockPeriod,
    address user
  ) internal {
    if (lockdropStates[user].lockdropTokenAmount > 0)
      revert Lockdrop_UserAlreadyLocked();
    if (amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (lockPeriod < (7 days) || lockPeriod > (7 days * 52))
      revert Lockdrop_InvalidLockPeriod(); // Less than 7 days or more than 364 days
    lockdropStates[user] = LockdropState({
      lockdropTokenAmount: amount,
      lockPeriod: lockPeriod,
      p88Claimed: false
    });
    totalAmount += amount;
    totalP88Weight += amount * lockPeriod;
    // Gateway call the function
    if (msg.sender == lockdropConfig.gatewayAddress()) {
      lockdropToken.safeTransferFrom(msg.sender, address(this), amount);
    } else {
      lockdropToken.safeTransferFrom(user, address(this), amount);
    }
    emit LogLockToken(user, amount, lockPeriod);
  }

  /// @dev Users can lock their ERC20 Token during the lockdrop period
  /// @param amount Number of token that user wants to lock
  /// @param lockPeriod Number of second that user wants to lock
  function lockToken(uint256 amount, uint256 lockPeriod)
    external
    onlyInLockdropPeriod
  {
    _lockTokenFor(amount, lockPeriod, msg.sender);
  }

  /// @dev Users can lock their ERC20 Token during the lockdrop period
  /// @param amount Number of token that user wants to lock
  /// @param lockPeriod Number of second that user wants to lock
  /// @param user Address of the user that wants to lock the token
  function lockTokenFor(
    uint256 amount,
    uint256 lockPeriod,
    address user
  ) external onlyInLockdropPeriod onlyGateway {
    _lockTokenFor(amount, lockPeriod, user);
  }

  function _extendLockPeriodFor(uint256 newLockPeriod, address user) internal {
    if (newLockPeriod > (7 days * 52)) revert Lockdrop_InvalidLockPeriod(); // New lock period should not be more than 364 days
    if (lockdropStates[user].lockdropTokenAmount == 0)
      revert Lockdrop_NoPosition();
    if (newLockPeriod < lockdropStates[user].lockPeriod)
      revert Lockdrop_InvalidLockPeriod();
    totalP88Weight +=
      lockdropStates[user].lockdropTokenAmount *
      (newLockPeriod - lockdropStates[user].lockPeriod);
    lockdropStates[user].lockPeriod = newLockPeriod;
    emit LogExtendLockPeriod(user, newLockPeriod);
  }

  /// @dev Users can extend their lock period during the lockdrop period
  /// @param newLockPeriod New number of second that user wants to lock
  function extendLockPeriod(uint256 newLockPeriod)
    external
    onlyInLockdropPeriod
  {
    _extendLockPeriodFor(newLockPeriod, msg.sender);
  }

  /// @dev Users can extend their lock period during the lockdrop period
  /// @param newLockPeriod New number of second that user wants to lock
  /// @param user Address of the user that wants extend the lock period
  function extendLockPeriodFor(uint256 newLockPeriod, address user)
    external
    onlyInLockdropPeriod
    onlyGateway
  {
    _extendLockPeriodFor(newLockPeriod, user);
  }

  function _addLockAmountFor(uint256 amount, address user) internal {
    if (amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (lockdropStates[user].lockdropTokenAmount == 0)
      revert Lockdrop_NoPosition();
    lockdropStates[user].lockdropTokenAmount += amount;
    totalAmount += amount;
    totalP88Weight += amount * lockdropStates[user].lockPeriod;
     // Gateway call the function
    if (msg.sender == lockdropConfig.gatewayAddress()) {
      lockdropToken.safeTransferFrom(msg.sender, address(this), amount);
    } else {
      lockdropToken.safeTransferFrom(user, address(this), amount);
    }
    emit LogAddLockAmount(user, amount);
  }

  /// @dev Users can add more lock amount during the lockdrop period
  /// @param amount Number of lock token that user wants to add
  function addLockAmount(uint256 amount) external onlyInLockdropPeriod {
    _addLockAmountFor(amount, msg.sender);
  }

  /// @dev Users can add more lock amount during the lockdrop period
  /// @param amount Number of lock token that user wants to add
  function addLockAmountFor(uint256 amount, address user)
    external
    onlyInLockdropPeriod
    onlyGateway
  {
    _addLockAmountFor(amount, user);
  }

  function _getEarlyWithdrawableAmount(address user)
    internal
    view
    returns (uint256 amount)
  {
    uint256 startRestrictedWithdrawalTimestamp = lockdropConfig
      .startRestrictedWithdrawalTimestamp();
    uint256 lockdropTokenAmount = lockdropStates[user].lockdropTokenAmount;
    uint256 decayPercentage = lockdropConfig.decayStartPercentage();
    if (block.timestamp < startRestrictedWithdrawalTimestamp)
      return lockdropTokenAmount;
    if (block.timestamp >= startRestrictedWithdrawalTimestamp) {
      if (
        block.timestamp >= lockdropConfig.startDecayingWithdrawalTimestamp()
      ) {
        return
          (((decayPercentage *
            (lockdropConfig.endLockTimestamp() - block.timestamp)) /
            lockdropConfig.startTimeDecay()) * lockdropTokenAmount) / 100;
      }
      return ((lockdropTokenAmount * decayPercentage) / 100);
    }
  }

  /// @dev Withdrawable amount calculation logic
  /// @param user Address of user that we want to know their valid withdraw amount
  function getEarlyWithdrawableAmount(address user)
    external
    view
    returns (uint256)
  {
    return _getEarlyWithdrawableAmount(user);
  }

  /// @dev Users able to withdraw their ERC20 Token within lockdrop period
  /// @param amount Number of token that user wants to withdraw
  /// @param user Address of the user that wants to withdraw
  function earlyWithdrawLockedToken(uint256 amount, address user)
    external
    onlyInLockdropPeriod
  {
    uint256 lockdropTokenAmount = lockdropStates[user].lockdropTokenAmount;
    if (amount == 0) revert Lockdrop_ZeroAmountNotAllowed();
    if (amount > lockdropTokenAmount) revert Lockdrop_InsufficientBalance();
    if (amount > _getEarlyWithdrawableAmount(user))
      revert Lockdrop_InvalidAmount();

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

  /// @dev Users able to withdraw all their PLP Token after the end of the lockdrop period + their input lock period
  /// @param user Address of the user that wants to withdraw
  function withdrawAll(address user) external {
    if (totalPLPAmount == 0) revert Lockdrop_ZeroTotalPLPAmount();
    if (
      block.timestamp <
      lockdropStates[user].lockPeriod + lockdropConfig.endLockTimestamp()
    ) revert Lockdrop_InvalidWithdrawAllPeriod();
    uint256 userPLPTokenAmount = (lockdropStates[user].lockdropTokenAmount *
      totalPLPAmount) / totalAmount;
    lockdropConfig.plpStaking().withdraw(
      address(this),
      address(lockdropConfig.plpToken()),
      userPLPTokenAmount
    );
    lockdropConfig.plpToken().safeTransfer(user, userPLPTokenAmount);
    delete lockdropStates[user];
    emit LogWithdrawAll(user, address(lockdropToken));
  }

  /// @dev Owner of the contract can allocate P88
  /// @param amount Number of P88 that feeder will feed
  function allocateP88(uint256 amount)
    external
    onlyAfterLockdropPeriod
    onlyOwner
  {
    // Prevent multiple call
    if (totalP88 > 0) revert Lockdrop_AlreadyAllocateP88();
    totalP88 = amount;
    lockdropConfig.p88Token().safeTransferFrom(
      address(owner()),
      address(this),
      amount
    );
    emit LogAllocateP88(amount);
  }

  /// @dev Users can claim their P88, this is a one time claim
  /// @param user Address of the user that wants to claim P88
  function claimAllP88(address user) external onlyAfterLockdropPeriod {
    if (lockdropStates[msg.sender].lockdropTokenAmount == 0)
      revert Lockdrop_NoPosition();
    if (totalP88 == 0) revert Lockdrop_ZeroTotalP88NotAllowed();
    if (totalP88Weight == 0) revert Lockdrop_ZeroP88WeightNotAllowed();
    if (lockdropStates[user].p88Claimed) revert Lockdrop_P88AlreadyClaimed();
    uint256 p88Amount = (totalP88 *
      lockdropStates[user].lockdropTokenAmount *
      lockdropStates[user].lockPeriod) / totalP88Weight;
    lockdropConfig.p88Token().safeTransfer(user, p88Amount);
    lockdropStates[user].p88Claimed = true;
    emit LogClaimAllP88(user, p88Amount);
  }

  // /// @dev Users can claim all their reward
  // /// @param user Address of the user that wants to claim the reward
  function claimAllReward(address user) external onlyAfterLockdropPeriod {
    //   lockdropConfig.plpStaking().harvest();
  }

  /// @dev PLP token is staked after the lockdrop period
  /// Recieve number of PLP after staking ERC20 Token
  function stakePLP() external onlyAfterLockdropPeriod onlyOwner {
    if (totalPLPAmount > 0) revert Lockdrop_PLPAlreadyStaked();
    totalPLPAmount = strategy.execute(totalAmount, address(lockdropToken));
    lockdropConfig.plpStaking().deposit(
      address(this),
      address(lockdropConfig.plpToken()),
      totalPLPAmount
    );
    emit LogStakePLP(totalPLPAmount);
  }
}
