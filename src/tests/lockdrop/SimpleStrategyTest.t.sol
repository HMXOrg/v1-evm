// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { SimpleStrategy } from "../../lockdrop/SimpleStrategy.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { MockPool } from "../mocks/MockPool.sol";
import { console } from "../utils/console.sol";

contract SimpleStrategyTest is BaseTest {
  SimpleStrategy internal strategy;
  MockErc20 internal baseToken;
  MockPool internal pool;

  function setUp() external {
    pool = new MockPool();
    baseToken = new MockErc20("Etherium", "ETH", 18);
    strategy = new SimpleStrategy(pool);
  }

  function test_ExecuteStrategy() external {
    // User Approve Token
    baseToken.mint(address(this), 10 ether);
    baseToken.approve(address(strategy), 10 ether);

    // Execute Strategy
    assertEq(strategy.execute(1, address(baseToken)), 20);
  }

  function test_NegativeNonApproveToken() external {
    // User Not Approve Token
    // Execute Strategy
    try strategy.execute(1, address(baseToken)) {} catch Error(
      string memory reason
    ) {
      // Throw Error
      assertEq("ERC20: insufficient allowance", reason);
      console.log("Error ", reason);
    }
  }
}
