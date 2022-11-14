// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "./base/BaseTest.sol";

contract DemoTest is BaseTest {
  function setUp() external {}

  function testForgeTool() external {
    uint256 x = 100;
    assertEq(x, 100);
  }
}
