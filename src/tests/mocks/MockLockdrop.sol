// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ILockdrop } from "../../lockdrop/interfaces/ILockdrop.sol";
import { MockErc20 } from "./MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console } from "../utils/console.sol";
import { MockLockdropConfig } from "./MockLockdropConfig.sol";

contract MockLockdrop is ILockdrop {
  using SafeERC20 for IERC20;

  address internal lockeDropTokenAddress;
  MockLockdropConfig internal lockdropConfig;

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
  }

  function extendLockPeriod(uint256 _lockPeriod) external {}

  function addLockAmount(uint256 _amount) external {}

  function earlyWithdrawLockedToken(uint256 _amount, address _user) external {}

  function claimAllRewards(address _user) external {
    lockdropConfig.p88Token().mint(address(this), 10 ether);
    lockdropConfig.p88Token().approve(address(this), 10 ether);

    lockdropConfig.plpToken().mint(address(this), 10 ether);
    lockdropConfig.plpToken().approve(address(this), 10 ether);

    IERC20(address(lockdropConfig.p88Token())).safeTransferFrom(
      address(this),
      _user,
      IERC20(address(lockdropConfig.p88Token())).balanceOf(address(this))
    );

    IERC20(address(lockdropConfig.plpToken())).safeTransferFrom(
      address(this),
      _user,
      IERC20(address(lockdropConfig.plpToken())).balanceOf(address(this))
    );
  }

  function stakePLP() external {}

  function withdrawAll(address _user) external {
    IERC20(lockeDropTokenAddress).approve(
      address(this),
      IERC20(lockeDropTokenAddress).balanceOf(address(this))
    );
    IERC20(lockeDropTokenAddress).safeTransferFrom(
      address(this),
      _user,
      IERC20(lockeDropTokenAddress).balanceOf(address(this))
    );
  }

  function claimAllP88(address _user) external {
    lockdropConfig.p88Token().mint(address(this), 10 ether);
    lockdropConfig.p88Token().approve(address(this), 10 ether);

    IERC20(address(lockdropConfig.p88Token())).safeTransferFrom(
      address(this),
      _user,
      IERC20(address(lockdropConfig.p88Token())).balanceOf(address(this))
    );
  }
}
