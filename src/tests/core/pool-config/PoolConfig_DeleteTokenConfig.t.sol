// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest, console, PoolConfig } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_DeleteTokenConfigTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory configs
    ) = buildDefaultSetTokenConfigInput();

    poolConfig.setTokenConfigs(tokens, configs);
  }

  function testRevert_WhenNotOwnerTryDeleteTokenConfig() external {
    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.deleteTokenConfig(address(dai));

    vm.stopPrank();
  }

  function testRevert_WhenDeleteNotExistedTokenConfig() external {
    vm.expectRevert(abi.encodeWithSignature("LinkedList_NotExisted()"));
    poolConfig.deleteTokenConfig(address(usdc));
  }

  function testCorrectness_WhenDeleteOneTokenConfig() external {
    // Delete DAI from the token list
    poolConfig.deleteTokenConfig(address(dai));

    // Assert total token weight has been decreased
    assertEq(poolConfig.totalTokenWeight(), 20000);

    // Assert allow token length
    assertEq(poolConfig.getAllowTokensLength(), 2);

    // Assert no DAI in the linkedlist
    assertTokenNotInLinkedlist(address(dai));

    // Assert token meta of DAI
    assertFalse(poolConfig.isAcceptToken(address(dai)));
    assertFalse(poolConfig.isStableToken(address(dai)));
    assertFalse(poolConfig.isShortableToken(address(dai)));
    assertEq(poolConfig.getTokenDecimalsOf(address(dai)), 0);
    assertEq(poolConfig.getTokenWeightOf(address(dai)), 0);
    assertEq(poolConfig.getTokenMinProfitBpsOf(address(dai)), 0);
    assertEq(poolConfig.getTokenUsdDebtCeilingOf(address(dai)), 0);
    assertEq(poolConfig.getTokenShortCeilingOf(address(dai)), 0);
    assertEq(poolConfig.getTokenBufferLiquidityOf(address(dai)), 0);
  }

  function testCorrectness_WhenDeleteAllTokenConfigs() external {
    // Delete all token configs
    poolConfig.deleteTokenConfig(address(dai));
    poolConfig.deleteTokenConfig(address(wbtc));
    poolConfig.deleteTokenConfig(address(matic));

    // Assert total token weight should be 0.
    assertEq(poolConfig.totalTokenWeight(), 0);

    // Assert allow token length should be 0
    assertEq(poolConfig.getAllowTokensLength(), 0);

    // Assert no tokens in the linkedlist
    assertTokenNotInLinkedlist(address(dai));
    assertTokenNotInLinkedlist(address(wbtc));
    assertTokenNotInLinkedlist(address(matic));

    // Assert token meta of DAI
    assertFalse(poolConfig.isAcceptToken(address(dai)));
    assertFalse(poolConfig.isStableToken(address(dai)));
    assertFalse(poolConfig.isShortableToken(address(dai)));
    assertEq(poolConfig.getTokenDecimalsOf(address(dai)), 0);
    assertEq(poolConfig.getTokenWeightOf(address(dai)), 0);
    assertEq(poolConfig.getTokenMinProfitBpsOf(address(dai)), 0);
    assertEq(poolConfig.getTokenUsdDebtCeilingOf(address(dai)), 0);
    assertEq(poolConfig.getTokenShortCeilingOf(address(dai)), 0);
    assertEq(poolConfig.getTokenBufferLiquidityOf(address(dai)), 0);

    // Assert token meta of WBTC
    assertFalse(poolConfig.isAcceptToken(address(wbtc)));
    assertFalse(poolConfig.isStableToken(address(wbtc)));
    assertFalse(poolConfig.isShortableToken(address(wbtc)));
    assertEq(poolConfig.getTokenDecimalsOf(address(wbtc)), 0);
    assertEq(poolConfig.getTokenWeightOf(address(wbtc)), 0);
    assertEq(poolConfig.getTokenMinProfitBpsOf(address(wbtc)), 0);
    assertEq(poolConfig.getTokenUsdDebtCeilingOf(address(wbtc)), 0);
    assertEq(poolConfig.getTokenShortCeilingOf(address(wbtc)), 0);
    assertEq(poolConfig.getTokenBufferLiquidityOf(address(wbtc)), 0);

    // Assert token meta of MATIC
    assertFalse(poolConfig.isAcceptToken(address(matic)));
    assertFalse(poolConfig.isStableToken(address(matic)));
    assertFalse(poolConfig.isShortableToken(address(matic)));
    assertEq(poolConfig.getTokenDecimalsOf(address(matic)), 0);
    assertEq(poolConfig.getTokenWeightOf(address(matic)), 0);
    assertEq(poolConfig.getTokenMinProfitBpsOf(address(matic)), 0);
    assertEq(poolConfig.getTokenUsdDebtCeilingOf(address(matic)), 0);
    assertEq(poolConfig.getTokenShortCeilingOf(address(matic)), 0);
    assertEq(poolConfig.getTokenBufferLiquidityOf(address(matic)), 0);
  }

  function testCorrectness_WhenDeleteThenAddBack() external {
    // Delete MATIC from the token list
    poolConfig.deleteTokenConfig(address(matic));

    // Add MATIC back with different token weight
    address[] memory updateTokens = new address[](1);
    updateTokens[0] = address(matic);

    PoolConfig.TokenConfig[]
      memory updateConfigs = new PoolConfig.TokenConfig[](1);
    updateConfigs[0] = PoolConfig.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: matic.decimals(),
      weight: 500,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0
    });

    poolConfig.setTokenConfigs(updateTokens, updateConfigs);

    // Assert token weights
    assertEq(poolConfig.getTokenWeightOf(address(dai)), 10000);
    assertEq(poolConfig.getTokenWeightOf(address(wbtc)), 10000);
    assertEq(poolConfig.getTokenWeightOf(address(matic)), 500);

    // Assert total token weight
    assertEq(poolConfig.totalTokenWeight(), 20500);

    // Assert allow tokens length
    assertEq(poolConfig.getAllowTokensLength(), 3);

    assertTokenInLinkedlist(address(matic));
  }
}
