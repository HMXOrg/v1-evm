// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../base/DSTest.sol";
import { console } from "../utils/console.sol";
import { BaseTest } from "../base/BaseTest.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockPool } from "../mocks/MockPool.sol";
import { SimpleStrategy } from "../../lockdrop/SimpleStrategy.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LockdropConfig } from "../../lockdrop/LockdropConfig.sol";
import { PLPStaking } from "../../staking/PLPStaking.sol";
import { P88 } from "../../tokens/P88.sol";

abstract contract Lockdrop_BaseTest is BaseTest {
  using SafeERC20 for IERC20;

  Lockdrop internal lockdrop;
  MockErc20 internal mockERC20;
  MockErc20 internal mockPLPToken;
  MockPool internal pool;
  SimpleStrategy internal strategy;
  LockdropConfig internal lockdropConfig;
  PLPStaking internal plpStaking;
  P88 internal mockP88Token;

  function setUp() public virtual {
    pool = new MockPool();
    strategy = new SimpleStrategy(pool);
    mockERC20 = new MockErc20("Mock Token", "MT", 18);
    mockPLPToken = new MockErc20("PLP", "PLP", 18);
    mockP88Token = new P88();

    plpStaking = new PLPStaking();
    lockdropConfig = new LockdropConfig(
      100000,
      plpStaking,
      address(mockPLPToken),
      mockP88Token
    );
    lockdrop = new Lockdrop(address(mockERC20), strategy, lockdropConfig);
  }

  function testCorrectness_WhenLockdropIsInit() external {
    assertEq(address(lockdrop.lockdropToken()), address(mockERC20));
    assertEq(lockdropConfig.startLockTimestamp(), uint256(100000));
    assertEq(lockdropConfig.endLockTimestamp(), uint256(704800));
    assertEq(lockdropConfig.withdrawalTimestamp(), uint256(532000));
  }
}
