// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { PLPStaking_BaseTest } from "./PLPStaking_BaseTest.t.sol";
import { console } from "../../utils/console.sol";

contract PLPStaking_Deposit is PLPStaking_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_RemoveRewarder() external {
    vm.startPrank(DAVE);

    plpStaking.removeRewarderForTokenByIndex(1, address(plp));

    assertEq(
      address(revenueRewarder),
      plpStaking.stakingTokenRewarders(address(plp), 0)
    );
    assertEq(
      address(partnerARewarder),
      plpStaking.stakingTokenRewarders(address(plp), 1)
    );

    // Mint 604800 esP88 to Feeder
    esP88.mint(DAVE, 604800 ether);
    // Mint 1000 PLP to Alice
    plp.mint(ALICE, 1000 ether);
    // Mint 1000 PLP to Bob
    plp.mint(BOB, 1000 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    plp.approve(address(plpStaking), type(uint256).max);
    // Alice deposits 100 PLP
    plpStaking.deposit(ALICE, address(plp), 100 ether);
    vm.stopPrank();

    // after 1 hours
    vm.warp(block.timestamp + 1 hours);

    vm.startPrank(DAVE);
    esP88.approve(address(esP88Rewarder), type(uint256).max);
    // Feeder feed esP88 to esP88Rewarder
    // 604800 / 7 day rewardPerSec ~= 1 esP88
    esP88Rewarder.feed(604800 ether, 7 days);
    vm.stopPrank();

    // after 1 hours
    vm.warp(block.timestamp + 1 hours);

    vm.startPrank(BOB);
    plp.approve(address(plpStaking), type(uint256).max);
    // Bob deposits 100 PLP
    plpStaking.deposit(BOB, address(plp), 100 ether);
    vm.stopPrank();
  }
}
