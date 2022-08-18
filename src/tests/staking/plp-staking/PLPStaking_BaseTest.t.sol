// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest, PLPStaking, PLP, EsP88, MockErc20, Rewarder } from "../../base/BaseTest.sol";

contract PLPStaking_BaseTest is BaseTest {
  PLP internal plp;
  EsP88 internal esP88;
  MockErc20 internal revenueToken;
  MockErc20 internal partnerAToken;

  PLPStaking internal plpStaking;

  Rewarder internal revenueRewarder;
  Rewarder internal esP88Rewarder;
  Rewarder internal partnerARewarder;

  function setUp() public virtual {
    plpStaking = BaseTest.deployPLPStaking();

    plp = BaseTest.deployPLP();
    plp.setMinter(DAVE, true);

    esP88 = BaseTest.deployEsP88();
    esP88.setMinter(DAVE, true);

    revenueToken = BaseTest.deployMockErc20(
      "Protocol Revenue Token",
      "PRT",
      18
    );
    partnerAToken = BaseTest.deployMockErc20("Partner A", "PA", 18);

    revenueRewarder = BaseTest.deployRewarder(
      "Protocol Revenue Rewarder",
      address(revenueToken),
      address(plpStaking)
    );
    esP88Rewarder = BaseTest.deployRewarder(
      "esP88 Rewarder",
      address(esP88),
      address(plpStaking)
    );
    partnerARewarder = BaseTest.deployRewarder(
      "Partner A Rewarder",
      address(partnerAToken),
      address(plpStaking)
    );

    address[] memory rewarders = new address[](3);
    rewarders[0] = address(revenueRewarder);
    rewarders[1] = address(esP88Rewarder);
    rewarders[2] = address(partnerARewarder);
    // address[] memory rewarders = new address[](1);
    // rewarders[0] = address(esP88Rewarder);

    plpStaking.addStakingToken(address(plp), rewarders);
  }
}
