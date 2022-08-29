// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../base/DSTest.sol";
import { console } from "../utils/console.sol";
import { math } from "../utils/math.sol";
import { BaseTest, MockWNative } from "../base/BaseTest.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockPool } from "../mocks/MockPool.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LockdropConfig } from "../../lockdrop/LockdropConfig.sol";
import { PLPStaking } from "../../staking/PLPStaking.sol";
import { P88 } from "../../tokens/P88.sol";
import { PLP } from "../../tokens/PLP.sol";
import { EsP88 } from "../../tokens/EsP88.sol";
import { MockRewarder } from "../mocks/MockRewarder.sol";

abstract contract Lockdrop_BaseTest is BaseTest {
  using SafeERC20 for IERC20;

  Lockdrop internal lockdrop;
  MockErc20 internal mockERC20;
  MockPool internal pool;
  LockdropConfig internal lockdropConfig;
  PLPStaking internal plpStaking;
  P88 internal mockP88Token;
  PLP internal mockPLPToken;
  EsP88 internal mockEsP88;
  address[] internal rewardsTokenList;
  MockRewarder internal PRRewarder;
  address internal mockGateway;
  MockWNative internal mockMatic;

  function setUp() public virtual {
    pool = new MockPool();
    mockERC20 = new MockErc20("Mock Token", "MT", 18);
    mockPLPToken = new PLP();
    mockP88Token = new P88();
    mockEsP88 = new EsP88();
    mockMatic = deployMockWNative();

    rewardsTokenList.push(address(mockEsP88));
    rewardsTokenList.push(address(mockMatic));

    plpStaking = new PLPStaking();
    mockGateway = address(0x88);

    lockdropConfig = new LockdropConfig(
      100000,
      plpStaking,
      mockPLPToken,
      mockP88Token,
      mockGateway
    );
    PRRewarder = new MockRewarder();
    address[] memory rewarders1 = new address[](1);
    rewarders1[0] = address(PRRewarder);
    plpStaking.addStakingToken(address(mockPLPToken), rewarders1);
    mockP88Token.setMinter(address(this), true);

    lockdrop = new Lockdrop(
      address(mockERC20),
      pool,
      lockdropConfig,
      rewardsTokenList,
      address(mockMatic)
    );
  }

  function testCorrectness_WhenLockdropIsInit() external {
    assertEq(address(lockdrop.lockdropToken()), address(mockERC20));
    assertEq(lockdropConfig.startLockTimestamp(), 100000);
    assertEq(lockdropConfig.endLockTimestamp(), 100000 + 4 days);
    assertEq(
      lockdropConfig.startRestrictedWithdrawalTimestamp(),
      100000 + 3 days
    );
    assertEq(
      lockdropConfig.startDecayingWithdrawalTimestamp(),
      100000 + 3 days + 12 hours
    );
  }
}
