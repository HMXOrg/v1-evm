// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../../base/DSTest.sol";
import { BaseTest, PLPStaking, PLP, P88, EsP88, MockErc20, MockWNative, FeedableRewarder, WFeedableRewarder, Lockdrop, LockdropConfig } from "../../base/BaseTest.sol";

abstract contract Lockdrop_BaseTest is BaseTest {
  PLP internal plp;
  P88 internal p88;
  MockErc20 internal lockdropToken;
  EsP88 internal esP88;
  MockWNative internal revenueToken;

  PLPStaking internal plpStaking;

  WFeedableRewarder internal revenueRewarder;
  FeedableRewarder internal esP88Rewarder;
  FeedableRewarder internal PLPRewarder;

  LockdropConfig internal lockdropConfig;
  Lockdrop internal lockdrop;

  address internal mockGateway;

  function setUp() public virtual {
    mockGateway = address(0x88);
    lockdropToken = new MockErc20("Mock Token", "MT", 18);

    vm.startPrank(DAVE);
    plpStaking = BaseTest.deployPLPStaking();

    plp = BaseTest.deployPLP();
    plp.setMinter(DAVE, true);

    p88 = BaseTest.deployP88();
    p88.setMinter(DAVE, true);

    esP88 = BaseTest.deployEsP88();
    esP88.setMinter(DAVE, true);

    revenueToken = deployMockWNative();

    revenueRewarder = BaseTest.deployWFeedableRewarder(
      "Protocol Revenue Rewarder",
      address(revenueToken),
      address(plpStaking)
    );
    esP88Rewarder = BaseTest.deployFeedableRewarder(
      "esP88 Rewarder",
      address(esP88),
      address(plpStaking)
    );

    address[] memory rewarders = new address[](2);
    rewarders[0] = address(revenueRewarder);
    rewarders[1] = address(esP88Rewarder);

    plpStaking.addStakingToken(address(plp), rewarders);

    vm.stopPrank();
  }
}
