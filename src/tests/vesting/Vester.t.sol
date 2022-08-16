// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { Vester } from "../../vesting/Vester.sol";

import { MockERC20 } from "../mock/MockERC20.sol";

import { Math } from "../../utils/Math.sol";

contract Vester_Test is BaseTest {
  Vester private vester;
  MockERC20 private p88;
  MockERC20 private esP88;

  address private constant BURN_ADDRESS = address(1);
  address private constant TREASURY_ADDRESS = address(2);

  function setUp() external {
    esP88 = new MockERC20("Escrowed P88", "esP88");
    p88 = new MockERC20("P88", "P88");

    vester = new Vester(
      address(esP88),
      address(p88),
      BURN_ADDRESS,
      TREASURY_ADDRESS
    );

    esP88.mint(address(this), 100 ether);
    p88.mint(address(vester), 100 ether);
  }

  function testConstructor() external {
    assertEq(vester.esP88(), address(esP88));
    assertEq(vester.p88(), address(p88));
  }

  function testCorrectness_vestShouldWork(uint256 duration) external {
    vm.assume(duration > 0);
    vm.assume(duration <= 31536000);
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, duration);
    assertEq(esP88.balanceOf(address(this)), 0);

    uint256 userItemIndex = vester.nextItemId() - 1;

    (
      address owner,
      bool hasClaimed,
      uint256 amount,
      uint256 startTime,
      uint256 endTime
      
    ) = vester.items(userItemIndex);

    assertEq(owner, address(this));
    assertEq(amount, 100 ether);
    assertEq(endTime - startTime, duration);
    assertFalse(hasClaimed);
  }

  function testCorrectness_claimForAfterVestEndShouldWork() external {
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, 30000000);

    uint256 userItemIndex = vester.nextItemId() - 1;

    uint256 expectedP88Amount = vester.getUnlockAmount(100 ether, 30000000);

    vm.warp(block.timestamp + 31536000);
    vester.claimFor(address(this), userItemIndex);

    assertEq(p88.balanceOf(address(this)), expectedP88Amount);
    assertEq(esP88.balanceOf(BURN_ADDRESS), expectedP88Amount);
    assertEq(esP88.balanceOf(TREASURY_ADDRESS), 100 ether - expectedP88Amount);
  }

  function testCorrectness_claimForManyAfterAllVestEndShouldWork() external {
    uint256[] memory indexes = new uint256[](2);

    esP88.approve(address(vester), 100 ether);

    vester.vestFor(address(this), 50 ether, 30000000);
    indexes[0] = vester.nextItemId() - 1;

    vester.vestFor(address(this), 50 ether, 30000000);
    indexes[1] = vester.nextItemId() - 1;

    uint256 expectedP88Amount = vester.getUnlockAmount(100 ether, 30000000);

    vm.warp(block.timestamp + 31536000);
    vester.claimFor(address(this), indexes);

    assertEq(p88.balanceOf(address(this)), expectedP88Amount);
    assertEq(esP88.balanceOf(BURN_ADDRESS), expectedP88Amount);
    assertEq(esP88.balanceOf(TREASURY_ADDRESS), 100 ether - expectedP88Amount);
  }

  function testCorrectness_claimForDifferentOwnerAndDestinationShouldRevert()
    external
  {
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, 31536000);

    uint256 userItemIndex = vester.nextItemId() - 1;

    vm.warp(block.timestamp + 31536000);
    vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
    vester.claimFor(address(1), userItemIndex);
  }

  function testCorrectness_claimItemBeforeCompleteShouldRevert() external {
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, 31536000);

    uint256 userItemIndex = vester.nextItemId() - 1;

    vm.expectRevert(abi.encodeWithSignature("HasNotCompleted()"));
    vester.claimFor(address(this), userItemIndex);
  }

  function testCorrectness_claimItemThatHasBeenClaimedShouldRevert() external {
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, 31536000);

    uint256 userItemIndex = vester.nextItemId() - 1;

    vm.warp(block.timestamp + 31536000);
    vester.claimFor(address(this), userItemIndex);

    vm.expectRevert(abi.encodeWithSignature("Claimed()"));
    vester.claimFor(address(this), userItemIndex);
  }

  function testCorrectness_abortBeforeVestHasCompletedShouldWork() external {
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, 31536000);

    uint256 userItemIndex = vester.nextItemId() - 1;

    vm.warp(block.timestamp + 11536000);
    vester.abort(userItemIndex);
    assertEq(esP88.balanceOf(address(this)), 100 ether);
  }

  function testRevert_vestZeroTokenShouldRevert() external {
    esP88.approve(address(vester), 100 ether);
    vm.expectRevert(abi.encodeWithSignature("BadArgument()"));
    vester.vestFor(address(this), 0 ether, 31536001);
  }

  function testRevert_vestMoreThan1YearShouldRevert() external {
    esP88.approve(address(vester), 100 ether);
    vm.expectRevert(abi.encodeWithSignature("ExceedMaxDuration()"));
    vester.vestFor(address(this), 100 ether, 31536001);
  }

  function testRevert_abortFromNonOwnerShouldRevert() external {
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, 31536000);

    uint256 userItemIndex = vester.nextItemId() - 1;

    vm.prank(address(1234), address(1234));
    vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
    vester.abort(userItemIndex);
  }

  function testCorrectness_abortAfterTheVestIsCompletedButHasNotClaimedShouldWork() external {
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, 31536000);

    uint256 userItemIndex = vester.nextItemId() - 1;

    vm.warp(block.timestamp + 31536000);
    vester.abort(userItemIndex);

    assertEq(esP88.balanceOf(address(this)), 100 ether);
  }

    function testRevert_abortAfterclaimForShouldRevert() external {
    esP88.approve(address(vester), 100 ether);
    vester.vestFor(address(this), 100 ether, 31536000);

    uint256 userItemIndex = vester.nextItemId() - 1;

    vm.warp(block.timestamp + 31536000);
    vester.claimFor(address(this), userItemIndex);

    vm.expectRevert(abi.encodeWithSignature("Claimed()"));
    vester.abort(userItemIndex);
  }

  function testCorrectness_calUnlockAmountShouldWork(
    uint256 amount,
    uint256 duration
  ) external {
    // assuming maximum amount of esp88 to vest is 1e30
    vm.assume(amount < 1e30);
    vm.assume(duration > 0);
    vm.assume(duration <= 31536000);

    uint256 ratioX18 = (uint256(duration * 1e18)) / 31536000;
    uint256 sqrtRatioX18 = Math.sqrt(ratioX18) * 1e9;

    assertEq(
      (amount * ((ratioX18 * sqrtRatioX18) / 1e18)) / 1e18,
      vester.getUnlockAmount(amount, duration)
    );
  }
}
