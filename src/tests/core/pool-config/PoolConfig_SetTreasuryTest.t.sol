// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetTreasuryTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetTreasury() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setTreasury(ALICE);

    vm.stopPrank();
  }

  function testCorrectness_WhenSetTreasurySuccessfully() external {
    poolConfig.setTreasury(ALICE);
    assertEq(poolConfig.treasury(), ALICE);
  }
}
