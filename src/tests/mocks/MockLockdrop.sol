// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ILockdrop } from "../../lockdrop/interfaces/ILockdrop.sol";
import { MockErc20 } from "./MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console } from "../utils/console.sol";

contract MockLockdrop {
  using SafeERC20 for IERC20;

  uint256 lockedTokenAmount;
  address lockedTokenAddress;
  MockErc20 p88;

  function getP88Address() external view returns (address) {
    return address(p88);
  }

  function withdrawLockToken(uint256 _amount, address _user) external {
    IERC20(lockedTokenAddress).approve(address(this), _amount);
    IERC20(lockedTokenAddress).safeTransferFrom(address(this), _user, _amount);
  }

  function claimAllReward(address _user) external {
    IERC20(address(p88)).safeTransferFrom(
      address(this),
      _user,
      IERC20(address(p88)).balanceOf(address(this))
    );
  }

  function lockToken(
    address _token,
    uint256 _amount,
    uint256 _lockPeriod
  ) external {
    lockedTokenAddress = _token;
    lockedTokenAmount = _amount;

    IERC20(_token).safeTransferFrom(
      msg.sender,
      address(this),
      lockedTokenAmount
    );

    p88 = new MockErc20("P88", "P88", 18);
    p88.mint(address(this), 20 ether);
    p88.approve(address(this), 20 ether);
  }
}
