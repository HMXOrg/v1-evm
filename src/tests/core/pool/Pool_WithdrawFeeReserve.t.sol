// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Pool_BaseTest, console, stdError, Pool, PoolConfig } from "./Pool_BaseTest.t.sol";

contract Pool_WithdrawFeeReserveTest is Pool_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory tokenConfigs
    ) = buildDefaultSetTokenConfigInput();

    poolConfig.setTokenConfigs(tokens, tokenConfigs);

    // Feed prices
    daiPriceFeed.setLatestAnswer(1 * 10**8);
    wbtcPriceFeed.setLatestAnswer(60000 * 10**8);
    maticPriceFeed.setLatestAnswer(300 * 10**8);
  }

  function testRevert_WhenMsgSenderNotTreasury() external {
    vm.expectRevert(abi.encodeWithSignature("Pool_Forbidden()"));
    pool.withdrawFeeReserve(address(dai), address(this), type(uint256).max);
  }

  function testRevert_WhenWithdrawMoreThanAvaliableFee() external {
    vm.startPrank(TREASURY);

    vm.expectRevert(stdError.arithmeticError);
    pool.withdrawFeeReserve(address(dai), address(this), type(uint256).max);

    vm.stopPrank();
  }

  function testCorrectness_WhenWithdrawFeeReserveCorrectly() external {
    // Add 1000 DAI as a liquidity
    dai.mint(address(pool), 1000 * 10**18);
    pool.addLiquidity(address(this), address(dai), address(this));

    // Assert pool's DAI fee reserved.
    // 1. Pool's DAI fee should be:
    // = 1000 * 0.003 = 3 DAI
    assertEq(pool.feeReserveOf(address(dai)), 3 * 10**18);

    // -- Start Treasury session ---
    vm.startPrank(TREASURY);

    // Withdraw 1 DAI from fee reserve to Alice
    pool.withdrawFeeReserve(address(dai), ALICE, 1 * 10**18);

    // The following conditions need to be met:
    // 1. Alice should get 1 DAI
    // 2. Pool's DAI fee should be 2 DAI
    assertEq(dai.balanceOf(ALICE), 1 * 10**18);
    assertEq(pool.feeReserveOf(address(dai)), 2 * 10**18);

    // Withdraw the rest of fee reserve to Bob
    pool.withdrawFeeReserve(address(dai), BOB, 2 * 10**18);

    // The following conditions need to be met:
    // 1. Bob should get 2 DAI
    // 2. Pool's DAI fee should be 0 DAI
    assertEq(dai.balanceOf(BOB), 2 * 10**18);
    assertEq(pool.feeReserveOf(address(dai)), 0);

    checkPoolBalanceWithState(address(dai), 0);
  }
}
