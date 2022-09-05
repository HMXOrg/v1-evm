// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { PoolConfig_BaseTest } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetMintBurnFeeBpsTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetMintBurnFeeBps() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setMintBurnFeeBps(1);

    vm.stopPrank();
  }

  function testRevert_WhenNewMintBurnFeeBpsMoreThanMaxMintBurnFeeBps()
    external
  {
    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_BadNewMintBurnFeeBps()")
    );
    poolConfig.setMintBurnFeeBps(501);
  }

  function testCorrectness_WhenSetMintBurnFeeBpsSuccessfully() external {
    poolConfig.setMintBurnFeeBps(500);

    assertEq(poolConfig.mintBurnFeeBps(), 500);
  }
}
