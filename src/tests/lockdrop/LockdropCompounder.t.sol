// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { EsP88 } from "../../tokens/EsP88.sol";
import { PLPStaking } from "../../staking/PLPStaking.sol";
import { DragonStaking } from "../../staking/DragonStaking.sol";
import { LockdropCompounder } from "../../lockdrop/LockdropCompounder.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseTest, MockWNative, console } from "../base/BaseTest.sol";
import { MockRewarder } from "../mocks/MockRewarder.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { ILockdrop } from "../../lockdrop/interfaces/ILockdrop.sol";
import { IPool } from "../../interfaces/IPool.sol";
import { MockPool } from "../mocks/MockPool.sol";
import { LockdropConfig } from "../../lockdrop/LockdropConfig.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { P88 } from "../../tokens/P88.sol";
import { PLP } from "../../tokens/PLP.sol";
import { MockPLPStaking } from "../mocks/MockPLPStaking.sol";
import { DragonStaking } from "../../staking/DragonStaking.sol";
import { IRewarder } from "../../staking/interfaces/IRewarder.sol";
import { FeedableRewarder } from "../../staking/FeedableRewarder.sol";

contract Lockdrop_StakePLP is BaseTest {
  MockErc20 internal mockERC20;
  PLP internal mockPLPToken;
  P88 internal mockP88Token;
  EsP88 internal mockEsP88Token;
  MockWNative internal mockWMaticToken;
  MockErc20 internal lockdropToken;
  address[] internal rewardsTokenList;
  LockdropConfig internal lockdropConfig;
  Lockdrop internal lockdrop;
  MockPLPStaking internal mockPLPStaking;
  MockPool internal pool;
  address internal mockGateway;
  DragonStaking internal dragonStaking;

  LockdropCompounder internal lockdropCompounder;

  address[] internal lockdrops;

  PLPStaking internal plpStaking;

  MockRewarder internal mockRewarder;
  IRewarder internal esP88rewarder1;
  IRewarder internal esP88rewarder2;
  IRewarder internal wMaticRewarder;
  address[] internal rewarders1;
  address[] internal rewarders2;

  function setUp() public {
    // Token
    mockERC20 = new MockErc20("Mock Token", "MT", 18);
    mockPLPToken = new PLP();
    mockP88Token = new P88();
    mockEsP88Token = new EsP88();
    mockWMaticToken = deployMockWNative();
    dragonStaking = new DragonStaking(address(0x99));

    mockWMaticToken.deposit{ value: 100 ether }();

    mockPLPToken.setMinter(address(this), true);
    mockEsP88Token.setMinter(address(this), true);

    plpStaking = new PLPStaking();

    esP88rewarder1 = new FeedableRewarder(
      "EsP88rewarder",
      address(mockEsP88Token),
      address(plpStaking)
    );

    esP88rewarder2 = new FeedableRewarder(
      "EsP88rewarder",
      address(mockEsP88Token),
      address(dragonStaking)
    );

    wMaticRewarder = new FeedableRewarder(
      "WMaticRewarder",
      address(mockWMaticToken),
      address(plpStaking)
    );

    mockEsP88Token.mint(address(this), 2 * 1e12 ether);
    mockEsP88Token.approve(address(esP88rewarder1), 2 * 1e12 ether);
    mockWMaticToken.mint(address(this), 2 * 1e12 ether);
    mockWMaticToken.approve(address(wMaticRewarder), 2 * 1e12 ether);

    rewarders1 = new address[](2);
    rewarders1[0] = address(esP88rewarder1);
    rewarders1[1] = address(wMaticRewarder);
    rewarders2 = new address[](1);
    rewarders2[0] = address(esP88rewarder2);

    // Stake token = PLPToken
    // Reward token = WMatic and EsP88
    plpStaking.addStakingToken(address(mockPLPToken), rewarders1);

    rewardsTokenList.push(address(mockEsP88Token));
    rewardsTokenList.push(address(mockWMaticToken));

    // Dragon Staking
    dragonStaking.addStakingToken(address(mockEsP88Token), rewarders2);

    mockGateway = address(0x88);
    pool = new MockPool();

    lockdropConfig = new LockdropConfig(
      1 days,
      plpStaking,
      mockPLPToken,
      mockP88Token,
      mockGateway
    );

    lockdrop = new Lockdrop(
      address(mockERC20),
      pool,
      lockdropConfig,
      rewardsTokenList,
      address(mockWMaticToken)
    );

    lockdropCompounder = new LockdropCompounder(
      address(mockEsP88Token),
      dragonStaking
    );

    lockdrops.push(address(lockdrop));

    // Alice
    vm.warp(block.timestamp + 1 days);
    vm.startPrank(ALICE);
    mockERC20.mint(ALICE, 20 ether);
    mockERC20.approve(address(lockdrop), 20 ether);
    lockdrop.lockToken(16 ether, 8 days);
    vm.stopPrank();

    vm.warp(block.timestamp + 5 days);
    vm.startPrank(address(lockdrop));
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 100 ether);
    vm.stopPrank();

    vm.startPrank(address(this));
    // Owner mint PLPToken
    mockPLPToken.mint(address(lockdrop), 90 ether);
    mockPLPToken.approve(address(lockdropConfig.plpStaking()), 100 ether);
    lockdrop.stakePLP();
    // Mockpool return tokenLockAmount * 2
    assertEq(lockdrop.totalPLPAmount(), 32 ether);
    assertEq(
      mockPLPToken.balanceOf(address(lockdropConfig.plpStaking())),
      32 ether
    );
    // 90 ether - 32 ether
    assertEq(mockPLPToken.balanceOf(address(lockdrop)), 58 ether);
    mockEsP88Token.mint(address(lockdrop), 100 ether);
    mockEsP88Token.mint(address(lockdrop), 100 ether);
    // mint PLP tokens for PLPStaking

    vm.stopPrank();
  }

  function testCorrectness_LockdropCompound() external {
    vm.warp(block.timestamp + 10 days);
    vm.startPrank(ALICE);
    lockdropCompounder.compound(lockdrops);
    vm.stopPrank();
    // Should not be 0
    console.log('dragon staking after compound');
    console.log(IERC20(mockEsP88Token).balanceOf(address(dragonStaking)));
  }
}
