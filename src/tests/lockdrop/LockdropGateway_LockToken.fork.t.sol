// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { BaseTest, console } from "../base/BaseTest.sol";
import { LockdropGateway } from "../../lockdrop/LockdropGateway.sol";
import { MockLockdrop2 } from "../mocks/MockLockdrop2.sol";

// forge test -vvv --match-contract 'LockdropGateway_LockToken' --fork-url https://rpc.tenderly.co/fork/b9034711-f094-4ffe-9353-86fa37be3381

contract LockdropGateway_LockToken is BaseTest {
  LockdropGateway gateway;
  MockLockdrop2 daiLockdrop;
  MockLockdrop2 usdcLockdrop;
  MockLockdrop2 usdtLockdrop;
  MockLockdrop2 wbtcLockdrop;
  MockLockdrop2 wethLockdrop;

  // Tokens
  address internal constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
  address internal constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address internal constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
  address internal constant WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
  address internal constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

  // Other tokens
  address internal constant crvUSDBTCETH =
    0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3; // Curve V5 Token

  // Etc.
  address internal constant crvUSDBTCETHZap =
    0x1d8b86e3D88cDb2d34688e87E72F388Cb541B7C8;

  // Wallets
  address internal constant WHALE_1 =
    0xF977814e90dA44bFA03b6295A0616a897441aceC;
  address internal constant crvUSDBTCETHHolder =
    0x6c5384bBaE7aF65Ed1b6784213A81DaE18e528b2;

  function setUp() public {
    gateway = new LockdropGateway();
    daiLockdrop = new MockLockdrop2();
    usdcLockdrop = new MockLockdrop2();
    usdtLockdrop = new MockLockdrop2();
    wbtcLockdrop = new MockLockdrop2();
    wethLockdrop = new MockLockdrop2();

    // Base token
    gateway.setBaseTokenLockdropInfo(address(DAI), address(daiLockdrop));
    gateway.setBaseTokenLockdropInfo(address(USDC), address(usdcLockdrop));
    gateway.setBaseTokenLockdropInfo(address(USDT), address(usdtLockdrop));
    gateway.setBaseTokenLockdropInfo(address(WBTC), address(wbtcLockdrop));
    gateway.setBaseTokenLockdropInfo(address(WETH), address(wethLockdrop));

    // Curve V5
    gateway.setCurveV5TokenLockdropInfo(crvUSDBTCETH, crvUSDBTCETHZap, 5);
  }

  function _isExpectedFork() internal view returns (bool) {
    return
      block.number == 32331970 &&
      address(0x5AFA5a3F59DB1BB8a2f55ffDa994AF00a6A02a10).balance ==
      1597507664757010107;
  }

  function testCorrectness_LockBaseToken() external {
    if (!_isExpectedFork()) return;

    vm.startPrank(WHALE_1);

    // Approve
    IERC20(USDC).approve(address(gateway), type(uint256).max);
    IERC20(USDT).approve(address(gateway), type(uint256).max);

    // Whale lock USDC
    gateway.lockToken(address(USDC), 300000000 * 1e6, 30 days); // lockTokenFor
    gateway.lockToken(address(USDC), 10000000 * 1e6, 40 days); // extendLockPeriodFor, addLockAmountFor
    gateway.lockToken(address(USDC), 10000000 * 1e6, 0 days); // addLockAmountFor
    gateway.lockToken(address(USDC), 0, 50 days); // extendLockPeriodFor

    // Assert locked amount/period
    (uint256 lockedAmount, uint256 lockedPeriod, ) = usdcLockdrop
      .lockdropStates(WHALE_1);
    assertEq(lockedAmount, 320000000 * 1e6);
    assertEq(lockedPeriod, 50 days);

    // Assert call counts
    assertEq(usdcLockdrop.lockTokenForCallCount(), 1);
    assertEq(usdcLockdrop.extendLockPeriodForCallCount(), 2);
    assertEq(usdcLockdrop.addLockAmountForCallCount(), 2);
    vm.stopPrank();
  }

  function testCorrectness_LockCurveV5Token() external {
    if (!_isExpectedFork()) return;

    // Declarations
    MockLockdrop2[5] memory lockdrops = [
      daiLockdrop,
      usdcLockdrop,
      usdtLockdrop,
      wbtcLockdrop,
      wethLockdrop
    ];
    uint256[5] memory lockedAmountBefore;

    vm.startPrank(crvUSDBTCETHHolder);

    // Approve
    IERC20(crvUSDBTCETH).approve(address(gateway), type(uint256).max);

    // Lock crvUSDBTCETH
    gateway.lockToken(address(crvUSDBTCETH), 20 ether, 30 days); // lockTokenFor

    // Assertion
    for (uint256 i = 0; i < 5; i++) {
      (uint256 lockedAmount, uint256 lockedPeriod, ) = lockdrops[i]
        .lockdropStates(crvUSDBTCETHHolder);
      assertGt(lockedAmount, lockedAmountBefore[i]);
      assertEq(lockedPeriod, 30 days);
      lockedAmountBefore[i] = lockedAmount;
    }

    // Lock crvUSDBTCETH again
    gateway.lockToken(address(crvUSDBTCETH), 50 ether, 36 days); // lockTokenFor

    // Assertion
    for (uint256 i = 0; i < 5; i++) {
      (uint256 lockedAmount, uint256 lockedPeriod, ) = lockdrops[i]
        .lockdropStates(crvUSDBTCETHHolder);
      assertGt(lockedAmount, lockedAmountBefore[i]);
      assertEq(lockedPeriod, 36 days);
      lockedAmountBefore[i] = lockedAmount;
    }

    // Lock crvUSDBTCETH again, but with same period
    gateway.lockToken(address(crvUSDBTCETH), 75 ether, 36 days); // lockTokenFor

    // Assertion
    for (uint256 i = 0; i < 5; i++) {
      (uint256 lockedAmount, uint256 lockedPeriod, ) = lockdrops[i]
        .lockdropStates(crvUSDBTCETHHolder);
      assertGt(lockedAmount, lockedAmountBefore[i]);
      assertEq(lockedPeriod, 36 days);
      lockedAmountBefore[i] = lockedAmount;
    }

    // Lock crvUSDBTCETH again, but don't extend period
    gateway.lockToken(address(crvUSDBTCETH), 1 ether, 0 days); // lockTokenFor

    // Assertion
    for (uint256 i = 0; i < 5; i++) {
      (uint256 lockedAmount, uint256 lockedPeriod, ) = lockdrops[i]
        .lockdropStates(crvUSDBTCETHHolder);
      assertGt(lockedAmount, lockedAmountBefore[i]);
      assertEq(lockedPeriod, 36 days);
      lockedAmountBefore[i] = lockedAmount;
    }

    // // Lock crvUSDBTCETH, but with 0 amount
    // // Will revert as the crvUSDBTCETH does not allow removeLiquidity 0
    vm.expectRevert();
    gateway.lockToken(address(crvUSDBTCETH), 0 ether, 40 days); // lockTokenFor

    // Assert call counts
    assertEq(usdcLockdrop.lockTokenForCallCount(), 1);
    assertEq(usdcLockdrop.addLockAmountForCallCount(), 3);
    assertEq(usdcLockdrop.extendLockPeriodForCallCount(), 2);
    vm.stopPrank();
  }

  function testRevert_LockCurveV5Token_WithZeroAmount() external {
    if (!_isExpectedFork()) return;

    vm.startPrank(crvUSDBTCETHHolder);

    // Approve
    IERC20(crvUSDBTCETH).approve(address(gateway), type(uint256).max);

    // Lock crvUSDBTCETH, but with 0 amount
    // Will revert as the crvUSDBTCETH does not allow removeLiquidity 0
    vm.expectRevert();
    gateway.lockToken(address(crvUSDBTCETH), 0 ether, 40 days); // lockTokenFor

    vm.stopPrank();
  }
}
