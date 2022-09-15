// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PoolConfig_BaseTest, console, PoolConfig } from "./PoolConfig_BaseTest.t.sol";

contract PoolConfig_SetTokenConfigsTest is PoolConfig_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenNotOwnerTrySetTokenConfigs() external {
    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory configs
    ) = buildDefaultSetTokenConfigInput();

    vm.startPrank(ALICE);

    vm.expectRevert("Ownable: caller is not the owner");
    poolConfig.setTokenConfigs(tokens, configs);

    vm.stopPrank();
  }

  function testRevert_WhenTokensConfigLengthMisMatch() external {
    (
      ,
      PoolConfig.TokenConfig[] memory configs
    ) = buildDefaultSetTokenConfigInput();

    address[] memory tokens = new address[](2);

    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_TokensConfigsLengthMisMatch()")
    );
    poolConfig.setTokenConfigs(tokens, configs);
  }

  function testRevert_WhenConfigContainsNotAcceptToken() external {
    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory configs
    ) = buildDefaultSetTokenConfigInput();

    configs[0].accept = false;

    vm.expectRevert(
      abi.encodeWithSignature("PoolConfig_ConfigContainsNotAcceptToken()")
    );
    poolConfig.setTokenConfigs(tokens, configs);
  }

  function testCorrectness_WhenSetTokenConfigsSuccessfully() external {
    (
      address[] memory tokens,
      PoolConfig.TokenConfig[] memory configs
    ) = buildDefaultSetTokenConfigInput();

    poolConfig.setTokenConfigs(tokens, configs);

    // Assert allow tokens length
    assertEq(poolConfig.getAllowTokensLength(), 3);

    // Assert all tokens in allowTokens LinkedList
    assertTokenInLinkedlist(address(dai));
    assertTokenInLinkedlist(address(wbtc));
    assertTokenInLinkedlist(address(matic));

    // Assert token accept
    assertTrue(poolConfig.isAcceptToken(address(dai)));
    assertTrue(poolConfig.isAcceptToken(address(wbtc)));
    assertTrue(poolConfig.isAcceptToken(address(matic)));

    // Assert is stable
    assertTrue(poolConfig.isStableToken(address(dai)));
    assertFalse(poolConfig.isStableToken(address(wbtc)));
    assertFalse(poolConfig.isStableToken(address(matic)));

    // Assert is shortable
    assertFalse(poolConfig.isShortableToken(address(dai)));
    assertTrue(poolConfig.isShortableToken(address(wbtc)));
    assertTrue(poolConfig.isShortableToken(address(matic)));

    // Assert decimals
    assertEq(poolConfig.getTokenDecimalsOf(address(dai)), 18);
    assertEq(poolConfig.getTokenDecimalsOf(address(wbtc)), 8);
    assertEq(poolConfig.getTokenDecimalsOf(address(matic)), 18);

    // Assert token weights
    assertEq(poolConfig.getTokenWeightOf(address(dai)), 10000);
    assertEq(poolConfig.getTokenWeightOf(address(wbtc)), 10000);
    assertEq(poolConfig.getTokenWeightOf(address(matic)), 10000);

    // Assert total token weight
    assertEq(poolConfig.totalTokenWeight(), 30000);

    // Assert min profit bps
    assertEq(poolConfig.getTokenMinProfitBpsOf(address(dai)), 75);
    assertEq(poolConfig.getTokenMinProfitBpsOf(address(wbtc)), 75);
    assertEq(poolConfig.getTokenMinProfitBpsOf(address(matic)), 75);

    // Assert usd debt ceiling
    assertEq(poolConfig.getTokenUsdDebtCeilingOf(address(dai)), 0);
    assertEq(poolConfig.getTokenUsdDebtCeilingOf(address(wbtc)), 0);
    assertEq(poolConfig.getTokenUsdDebtCeilingOf(address(matic)), 0);

    // Assert short ceiling
    assertEq(poolConfig.getTokenShortCeilingOf(address(dai)), 0);
    assertEq(poolConfig.getTokenShortCeilingOf(address(wbtc)), 0);
    assertEq(poolConfig.getTokenShortCeilingOf(address(matic)), 0);

    // Assert buffer liquidity
    assertEq(poolConfig.getTokenBufferLiquidityOf(address(dai)), 0);
    assertEq(poolConfig.getTokenBufferLiquidityOf(address(wbtc)), 0);
    assertEq(poolConfig.getTokenBufferLiquidityOf(address(matic)), 0);

    // Update matic token weight
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
  }
}
