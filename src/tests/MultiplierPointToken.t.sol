// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest, console } from "./base/BaseTest.sol";
import { MultiplierPointToken } from "../tokens/MultiplierPointToken.sol";

contract MultiplierPointTokenTest is BaseTest {
  MultiplierPointToken internal multiplierPointToken;

  function setUp() external {
    multiplierPointToken = new MultiplierPointToken();
  }

  function testCorrectness_init() external {
    assertEq(multiplierPointToken.name(), "Multiplier Point Token");
    assertEq(multiplierPointToken.symbol(), "MPT");
  }

  function testCorrectness_setMinter() external {
    assertFalse(multiplierPointToken.isMinter(ALICE));
    multiplierPointToken.setMinter(ALICE, true);
    assertTrue(multiplierPointToken.isMinter(ALICE));
  }

  function testCorrectness_mint() external {
    multiplierPointToken.setMinter(ALICE, true);
    vm.startPrank(ALICE);
    multiplierPointToken.mint(BOB, 88 ether);
    assertEq(multiplierPointToken.balanceOf(BOB), 88 ether);
    vm.stopPrank();
  }

  function testRevert_mint() external {
    vm.expectRevert("MintableToken: forbidden");
    multiplierPointToken.mint(BOB, 88 ether);
  }

  function testCorrectness_burn() external {
    multiplierPointToken.setMinter(ALICE, true);
    multiplierPointToken.setBurner(ALICE, true);
    vm.startPrank(ALICE);
    multiplierPointToken.mint(BOB, 88 ether);
    assertEq(multiplierPointToken.balanceOf(BOB), 88 ether);
    multiplierPointToken.burn(BOB, 88 ether);
    assertEq(multiplierPointToken.balanceOf(BOB), 0 ether);
    vm.stopPrank();
  }

  function testRevert_burn() external {
    vm.expectRevert("BurnableToken: forbidden");
    multiplierPointToken.burn(BOB, 88 ether);
  }

  function test_WhenAliceBobTransferToken_BothWhitelisted_ShouldWork()
    external
  {
    multiplierPointToken.setMinter(ALICE, true);
    vm.startPrank(ALICE);
    multiplierPointToken.mint(BOB, 88 ether);
    vm.stopPrank();

    // ALICE: 0 MPT
    // BOB: 88 MPT
    assertEq(multiplierPointToken.balanceOf(ALICE), 0 ether);
    assertEq(multiplierPointToken.balanceOf(BOB), 88 ether);

    // Whitelist both
    multiplierPointToken.setTransferrer(ALICE, true);
    multiplierPointToken.setTransferrer(BOB, true);
    // Transfer BOB <-> ALICE
    vm.startPrank(BOB);
    multiplierPointToken.transfer(ALICE, 40 ether); // BOB -> ALICE 40
    vm.stopPrank();
    vm.startPrank(ALICE);
    multiplierPointToken.approve(ALICE, 2 ether);
    multiplierPointToken.transferFrom(ALICE, BOB, 2 ether); // ALICE -> BOB 2
    vm.stopPrank();

    // ALICE: 38 MPT
    // BOB: 50 MPT
    assertEq(multiplierPointToken.balanceOf(ALICE), 38 ether);
    assertEq(multiplierPointToken.balanceOf(BOB), 50 ether);
  }

  function test_WhenAliceBobTransferToken_NoneWhitelisted_ShouldFail()
    external
  {
    multiplierPointToken.setMinter(ALICE, true);
    vm.startPrank(ALICE);
    multiplierPointToken.mint(ALICE, 44 ether);
    multiplierPointToken.mint(BOB, 88 ether);
    vm.stopPrank();

    // Whitelist no one
    // Transfer BOB <-> ALICE
    vm.startPrank(BOB);
    vm.expectRevert(
      abi.encodeWithSignature("MultiplierPointToken_isNotTransferrable()")
    );
    multiplierPointToken.transfer(ALICE, 1 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    vm.expectRevert(
      abi.encodeWithSignature("MultiplierPointToken_isNotTransferrable()")
    );
    multiplierPointToken.transfer(BOB, 1 ether);
    vm.stopPrank();
  }

  function test_WhenAliceBobTransferToken_OnlyBobWhitelisted_ShouldFail()
    external
  {
    multiplierPointToken.setMinter(ALICE, true);
    vm.startPrank(ALICE);
    multiplierPointToken.mint(ALICE, 44 ether);
    multiplierPointToken.mint(BOB, 88 ether);
    vm.stopPrank();

    // White list BOB
    multiplierPointToken.setTransferrer(BOB, true);
    // Transfer BOB <-> ALICE
    vm.startPrank(BOB);
    vm.expectRevert(
      abi.encodeWithSignature("MultiplierPointToken_isNotTransferrable()")
    );
    multiplierPointToken.transfer(ALICE, 1 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    vm.expectRevert(
      abi.encodeWithSignature("MultiplierPointToken_isNotTransferrable()")
    );
    multiplierPointToken.transfer(BOB, 1 ether);
    vm.stopPrank();
  }
}
