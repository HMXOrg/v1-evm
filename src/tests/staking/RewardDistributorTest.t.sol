// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest } from "../base/BaseTest.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { RewardDistributor } from "../../staking/RewardDistributor.sol";
import { MockFeedableRewarder } from "../mocks/MockFeedableRewarder.sol";
import { MockPool } from "../mocks/MockPool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console } from "../utils/console.sol";

contract RewardDistributorTest is BaseTest {
  using SafeERC20 for IERC20;

  MockFeedableRewarder internal feedableRewarder;
  MockErc20 internal inToken1;
  MockErc20 internal inToken2;
  address[] internal inTokenList;
  MockErc20 internal rewardToken;
  MockPool internal pool;
  RewardDistributor internal rewardDistributor;

  function setUp() external {
    inToken1 = new MockErc20("PLP", "PLP", 18);
    inToken2 = new MockErc20("PLP", "PLP", 18);
    rewardToken = new MockErc20("Etherium", "ETH", 18);

    pool = new MockPool();
    feedableRewarder = new MockFeedableRewarder(address(rewardToken));

    rewardDistributor = new RewardDistributor(
      address(rewardToken),
      pool,
      feedableRewarder
    );
  }

  function testRevert_WhenSendInTheTokenToDistributor_ButNotAnOwner() external {
    inToken1.mint(address(this), 10 ether);
    inToken2.mint(address(this), 10 ether);

    inTokenList.push(address(inToken1));
    inTokenList.push(address(inToken2));

    inToken1.approve(address(this), 10 ether);
    inToken2.approve(address(this), 10 ether);

    //  Expect Revert
    vm.prank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    rewardDistributor.distributeToken(inTokenList);
  }

  function testCorrectness_WhenSendInTheTokenToDistributor_ThenDistibutorSwapTokenToRewardToken()
    external
  {
    inToken1.mint(address(this), 10 ether);
    inToken2.mint(address(this), 10 ether);

    inTokenList.push(address(inToken1));
    inTokenList.push(address(inToken2));

    inToken1.approve(address(this), 10 ether);
    inToken2.approve(address(this), 10 ether);

    IERC20(inToken1).safeTransferFrom(
      address(this),
      address(rewardDistributor),
      10 ether
    );

    IERC20(inToken2).safeTransferFrom(
      address(this),
      address(rewardDistributor),
      10 ether
    );

    assertEq(IERC20(inToken1).balanceOf(address(rewardDistributor)), 10 ether);
    assertEq(IERC20(inToken2).balanceOf(address(rewardDistributor)), 10 ether);

    rewardDistributor.distributeToken(inTokenList);

    assertEq(
      IERC20(rewardToken).balanceOf(address(rewardDistributor)),
      2 ether
    );
  }

  function testCorrectness_WhenFeedTheRewardTokenToFeedableRewarder() external {
    inToken1.mint(address(this), 10 ether);
    inToken2.mint(address(this), 10 ether);

    inTokenList.push(address(inToken1));
    inTokenList.push(address(inToken2));

    inToken1.approve(address(this), 10 ether);
    inToken2.approve(address(this), 10 ether);

    IERC20(inToken1).safeTransferFrom(
      address(this),
      address(rewardDistributor),
      10 ether
    );

    IERC20(inToken2).safeTransferFrom(
      address(this),
      address(rewardDistributor),
      10 ether
    );

    rewardDistributor.distributeToken(inTokenList);

    assertEq(
      IERC20(rewardToken).balanceOf(address(rewardDistributor)),
      2 ether
    );

    rewardDistributor.feedToRewarder(10 days);

    assertEq(IERC20(rewardToken).balanceOf(address(feedableRewarder)), 2 ether);
  }
}
