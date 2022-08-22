// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IStaking } from "../staking/interfaces/IStaking.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PLP } from "../tokens/PLP.sol";

// Universal setting for lockdrop last for 4 days where
// 1. Deposit period last for 4 days
// 2. First 3 days is 100% withdrawable
// 3. Withdraw day 4: First 12 hours 50 % withdrawable
// 4. Withdraw day 4: After 12 hours dacaying withdraw from 50% to 0%

contract LockdropConfig {
  // --- States ---
  IStaking public plpStaking;
  IERC20 public p88Token;
  IERC20 public plpToken;
  uint256 public startLockTimestamp; // timestamp for starting lockdrop event
  uint256 public endLockTimestamp; // timestamp for deposit period after start lockdrop event
  uint256 public withdrawalTimestampDecay; // timestamp for withdraw period after start lockdrop event
  uint256 public withdrawalTimestamp; // timestamp for withdraw period after start lockdrop event
  uint256 public decayStartPercentage;
  uint256 public startTimeDecay;

  constructor(
    uint256 _startLockTimestamp,
    IStaking _PLPStaking,
    IERC20 _PLPToken,
    IERC20 _p88Token
  ) {
    decayStartPercentage = 50;
    startTimeDecay = 12 hours;
    plpStaking = _PLPStaking;
    startLockTimestamp = _startLockTimestamp;
    endLockTimestamp = _startLockTimestamp + (5 days);
    withdrawalTimestamp = _startLockTimestamp + 4 days;
    withdrawalTimestampDecay = _startLockTimestamp + 4 days + startTimeDecay;
    plpToken = _PLPToken;
    p88Token = _p88Token;
  }
}
