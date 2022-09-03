// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetTaxBpsTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetTaxBps() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setTaxBps(1, 1);

    vm.stopPrank();
  }

  function testRevert_WhenNewTaxBpsMoreThanMaxTaxBps() external {
    vm.expectRevert(abi.encodeWithSignature("PoolConfig_BadNewTaxBps()"));
    poolConfig.setTaxBps(501, 1);
  }

  function testRevert_WhenNewStableTaxBpsMoreThanMaxTaxBps() external {
    vm.expectRevert(abi.encodeWithSignature("PoolConfig_BadNewStableTaxBps()"));
    poolConfig.setTaxBps(1, 501);
  }

  function testCorrectness_WhenSetTaxBpsSuccessfully() external {
    poolConfig.setTaxBps(500, 500);
    assertEq(poolConfig.taxBps(), 500);
    assertEq(poolConfig.stableTaxBps(), 500);
  }
}
