// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISimpleStrategy } from "./interfaces/ISimpleStrategy.sol";
import { IStaking } from "../staking/interfaces/IStaking.sol";
import { LockdropConfig } from "./LockdropConfig.sol";

contract LockdropConfig {

    // --- States ---
    IStaking public plpStaking;
    address public plpTokenAddress;
    uint256 public startLockTimestamp; // timestamp for starting lockdrop event
    uint256 public endLockTimestamp; // timestamp for deposit period after start lockdrop event
    uint256 public withdrawalTimestamp; // timestamp for withdraw period after start lockdrop event

    
    constructor(uint256 _startLockTimestamp, IStaking _PLPStaking, address _PLPTokenAddress) {
        plpStaking = _PLPStaking;
        startLockTimestamp = _startLockTimestamp;
        endLockTimestamp = _startLockTimestamp + (7 days);
        withdrawalTimestamp = _startLockTimestamp + (5 days);
        plpTokenAddress = _PLPTokenAddress; 
    }
}