// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Lockdrop is ReentrancyGuard, Ownable {
    
    // --- Libraries ---
    using SafeERC20 for IERC20;

    // --- Events ---
    event LogLockToken(address indexed account, address _token, uint256 _amount, uint256 _lockPeriod);

    // --- Custom Errors ---
    error LockDrop_ZeroAddressNotAllowed();
    error LockDrop_InvalidStartLockTimestamp();
    error LockDrop_InvalidLockPeriod();
    error LockDrop_MismatchToken();

    // --- Structs ---
    struct LockdropConfig {
        IERC20 lockdropToken; // lockdrop token address
        uint256 startLockTimestamp; // timestamp for starting lockdrop event
        uint256 endLockTimestamp; // timestamp for deposit period after start lockdrop event
        uint256 withdrawalTimestamp; // timestamp for withdraw period after start lockdrop event
    }

    struct LockdropState {
        uint256 lockdropTokenAmount;
        uint256 lockPeriod;
    }

    // --- States ---
    LockdropConfig public lockdropConfig;
    mapping(address => LockdropState) public LockdropStates;


    constructor(address _lockdropToken, uint256 _startLockTimestamp) {
        if (_lockdropToken == address(0)) revert LockDrop_ZeroAddressNotAllowed();
        if (block.timestamp > _startLockTimestamp) revert LockDrop_InvalidStartLockTimestamp();

        lockdropConfig = LockdropConfig(
             IERC20(_lockdropToken),
             _startLockTimestamp,
             _startLockTimestamp + 604800, // 7 days in second
             _startLockTimestamp + 432000 // 5 days in second
        );
    }

    /// @dev User lock ERC20 Token
    /// @param _token Token address that user wants to lock
    /// @param _amount Number of token that user wants to lock
    /// @param _lockPeriod Number of second that user wants to lock 
    function lockToken(address _token, uint256 _amount, uint256 _lockPeriod)external {
        if (_amount == 0) revert LockDrop_ZeroAddressNotAllowed();
        if (_lockPeriod < 604800) revert LockDrop_InvalidLockPeriod(); // Less than 1 week
        if (_lockPeriod > 31449600) revert LockDrop_InvalidLockPeriod(); // More than 52 weeks
        if (_token != address(lockdropConfig.lockdropToken)) revert LockDrop_MismatchToken(); // Mismatch token address

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        LockdropStates[msg.sender] = LockdropState({lockdropTokenAmount: _amount, lockPeriod: _lockPeriod});

        emit LogLockToken(msg.sender, _token, _amount, _lockPeriod);
    }

    function mintPLP() internal {
        // get number of PLP that should be mint
    }

    function stakePLP() internal {

    }

}
