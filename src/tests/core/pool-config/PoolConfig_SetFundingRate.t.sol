// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetFundingRateTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetFundingRate() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setFundingRate(1, 1, 1);

    vm.stopPrank();
  }

  function testRevert_WhenNewFundingIntervalLessThanMinFundingInterval()
    external
  {
    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_BadNewFundingInterval()")
    );
    poolConfig.setFundingRate(1, 1, 1);
  }

  function testRevert_WhenNewstableBorrowingRateFactorMoreThanMaxborrowingRateFactor()
    external
  {
    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_BadNewstableBorrowingRateFactor()")
    );
    poolConfig.setFundingRate(1 hours, 1, 10001);
  }

  function testRevert_WhenNewborrowingRateFactorMoreThanMaxborrowingRateFactor()
    external
  {
    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_BadNewborrowingRateFactor()")
    );
    poolConfig.setFundingRate(1 hours, 10001, 600);
  }

  function testCorrectness_WhenSetFundingRateSuccessfully() external {
    poolConfig.setFundingRate(1 hours, 600, 600);

    assertEq(poolConfig.fundingInterval(), 1 hours);
    assertEq(poolConfig.stableBorrowingRateFactor(), 600);
    assertEq(poolConfig.borrowingRateFactor(), 600);
  }
}
