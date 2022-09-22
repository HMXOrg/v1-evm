// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetMinProfitDurationTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetMinProfitDuration() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setMinProfitDuration(1);

    vm.stopPrank();
  }

  function testCorrectness_WhenSetMinProfitDurationSuccessfully() external {
    poolConfig.setMinProfitDuration(1);
    assertEq(poolConfig.minProfitDuration(), 1);
  }
}
