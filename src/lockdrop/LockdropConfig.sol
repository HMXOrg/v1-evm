// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IStaking } from "../staking/interfaces/IStaking.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockdropConfig {
  // --- States ---
  IStaking public plpStaking;
  IERC20 public p88Token;
  address public plpTokenAddress;
  uint256 public startLockTimestamp; // timestamp for starting lockdrop event
  uint256 public endLockTimestamp; // timestamp for deposit period after start lockdrop event
  uint256 public withdrawalTimestamp; // timestamp for withdraw period after start lockdrop event

  constructor(
    uint256 _startLockTimestamp,
    IStaking _PLPStaking,
    address _PLPTokenAddress,
    IERC20 _p88Token
  ) {
    plpStaking = _PLPStaking;
    startLockTimestamp = _startLockTimestamp;
    endLockTimestamp = _startLockTimestamp + (7 days);
    withdrawalTimestamp = _startLockTimestamp + (5 days);
    plpTokenAddress = _PLPTokenAddress;
    p88Token = _p88Token;
  }
}
