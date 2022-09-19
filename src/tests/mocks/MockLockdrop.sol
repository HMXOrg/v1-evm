// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ILockdrop } from "../../lockdrop/interfaces/ILockdrop.sol";
import { MockErc20 } from "./MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console } from "../utils/console.sol";
import { MockLockdropConfig } from "./MockLockdropConfig.sol";
import { IWNative } from "../../interfaces/IWNative.sol";

contract MockLockdrop is ILockdrop {
  using SafeERC20 for IERC20;

  address internal lockeDropTokenAddress;
  MockLockdropConfig internal lockdropConfig;
  uint256 internal lockTokenAmount;
  uint256 internal totalPLPAmount;

  constructor(address _lockdropToken, MockLockdropConfig _lockdropConfig) {
    lockeDropTokenAddress = _lockdropToken;
    lockdropConfig = _lockdropConfig;
  }

  function lockToken(uint256 _amount, uint256 _lockPeriod) external {
    IERC20(address(lockeDropTokenAddress)).safeTransferFrom(
      msg.sender,
      address(this),
      _amount
    );

    lockTokenAmount += _amount;
  }

  function extendLockPeriod(uint256 _lockPeriod) external {}

  function addLockAmount(uint256 _amount) external {}

  function earlyWithdrawLockedToken(uint256 _amount, address _user) external {}

  function _claimAllRewards(address _user) internal {
    IWNative(lockdropConfig.nativeToken()).withdraw(
      lockdropConfig.nativeToken().balanceOf(address(this))
    );
    payable(_user).transfer(address(this).balance);

    IERC20(lockdropConfig.esp88Token()).approve(
      address(this),
      IERC20(lockdropConfig.esp88Token()).balanceOf(address(this))
    );
    IERC20(lockdropConfig.esp88Token()).safeTransferFrom(
      address(this),
      _user,
      IERC20(lockdropConfig.esp88Token()).balanceOf(address(this))
    );
  }

  function claimAllRewardsFor(address user, address receiver) external {}

  function claimAllRewards(address _user) external {
    _claimAllRewards(_user);
  }

  function stakePLP() external {
    totalPLPAmount += lockTokenAmount;
    lockdropConfig.plpStaking().deposit(
      address(this),
      address(lockdropConfig.plpToken()),
      totalPLPAmount
    );
    lockTokenAmount = 0;
  }

  function withdrawAll(address _user) external {
    _claimAllRewards(_user);

    lockdropConfig.plpStaking().withdraw(
      address(lockdropConfig.plpToken()),
      totalPLPAmount
    );

    IERC20(lockdropConfig.plpToken()).approve(address(this), totalPLPAmount);
    IERC20(lockdropConfig.plpToken()).safeTransferFrom(
      address(this),
      msg.sender,
      totalPLPAmount
    );
    totalPLPAmount = 0;
  }

  function claimAllP88(address _user) external {
    lockdropConfig.p88Token().approve(address(this), 10 ether);

    IERC20(lockdropConfig.p88Token()).safeTransferFrom(
      address(this),
      _user,
      IERC20(lockdropConfig.p88Token()).balanceOf(address(this))
    );
  }

  function lockdropStates(address)
    external
    pure
    returns (
      uint256 lockdropTokenAmount,
      uint256 lockPeriod,
      bool p88Claimed,
      bool restrictedWithdrawn
    )
  {
    return (0, 0, false, false);
  }

  function lockTokenFor(
    uint256 amount,
    uint256 lockPeriod,
    address user
  ) external {}

  function extendLockPeriodFor(uint256 lockPeriod, address user) external {}

  function addLockAmountFor(uint256 amount, address user) external {}

  receive() external payable {}
}
