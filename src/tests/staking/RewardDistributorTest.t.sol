// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest, MerkleAirdrop, MerkleAirdropFactory, MerkleAirdropGateway } from "../base/BaseTest.sol";
import { MockErc20 } from "../mocks/MockERC20.sol";
import { RewardDistributor } from "../../staking/RewardDistributor.sol";
import { MockFeedableRewarder } from "../mocks/MockFeedableRewarder.sol";
import { MockPoolForRewardDistributor } from "../mocks/MockPoolForRewardDistributor.sol";
import { MockPoolRouterForRewardDistributor } from "../mocks/MockPoolRouterForRewardDistributor.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console } from "../utils/console.sol";

contract RewardDistributorTest is BaseTest {
  using SafeERC20 for IERC20;

  MockFeedableRewarder internal plpStakingProtocolRevenueRewarder;
  MockFeedableRewarder internal dragonStakingProtocolRevenueRewarder;
  MockErc20 internal wBtc;
  MockErc20 internal wEth;
  MockErc20 internal wMatic;
  MockErc20 internal mockUSDC;
  MockPoolForRewardDistributor internal pool;
  MockPoolRouterForRewardDistributor internal poolRouter;
  address devFund = address(8888);

  RewardDistributor internal rewardDistributor;

  MerkleAirdrop internal merkleAirdropTemplate;
  MerkleAirdropFactory internal merkleAirdropFactory;
  bytes32 internal merkleRoot =
    0xe8265d62c006291e55af5cc6cde08360d1362af700d61a06087c7ce21b2c31b8;
  bytes32 internal ipfsHash = keccak256("1");
  MerkleAirdrop internal merkleAirdrop;

  uint256 internal totalTokenAmount = 10 ether;

  function setUp() external {
    wBtc = new MockErc20("WBTC", "WBTC", 18);
    wEth = new MockErc20("WETH", "WETH", 18);
    wMatic = new MockErc20("WMATIC", "WMATIC", 18);
    mockUSDC = new MockErc20("WMATIC", "WMATIC", 6);

    // Behaviour: always mint 100 ether when withdraw reserve
    pool = new MockPoolForRewardDistributor();

    // Behaviour: swap x inToken, get x/2 outToken
    poolRouter = new MockPoolRouterForRewardDistributor();

    // Behaviour: just transferFrom when feed
    plpStakingProtocolRevenueRewarder = new MockFeedableRewarder(
      address(mockUSDC)
    );
    dragonStakingProtocolRevenueRewarder = new MockFeedableRewarder(
      address(mockUSDC)
    );

    merkleAirdropTemplate = deployMerkleAirdrop();
    merkleAirdropFactory = deployMerkleAirdropFactory();

    bytes32 salt = keccak256(abi.encode(block.timestamp, totalTokenAmount));
    merkleAirdrop = merkleAirdropFactory.createMerkleAirdrop(
      address(merkleAirdropTemplate),
      address(usdc),
      merkleRoot,
      block.timestamp + 7 days,
      salt,
      ipfsHash
    );

    rewardDistributor = deployRewardDistributor(
      address(mockUSDC),
      address(pool),
      address(poolRouter),
      address(plpStakingProtocolRevenueRewarder),
      address(dragonStakingProtocolRevenueRewarder),
      1200, // 12%
      7500,
      devFund,
      address(merkleAirdropFactory),
      address(merkleAirdropTemplate)
    );
  }

  function testCorrectness_WhenClaimAndFeedProtocolRevenue() external {
    address[] memory tokens = new address[](3);
    tokens[0] = address(wBtc);
    tokens[1] = address(wEth);
    tokens[2] = address(wMatic);

    rewardDistributor.claimAndFeedProtocolRevenue(
      tokens,
      block.timestamp + 3 days,
      block.timestamp,
      totalTokenAmount,
      merkleRoot
    );

    assertEq(wBtc.balanceOf(devFund), 12 ether);
    assertEq(wEth.balanceOf(devFund), 12 ether);
    assertEq(wMatic.balanceOf(devFund), 12 ether);

    // After distribution, there is 88 ether left for each token.
    // Then, each token will be swapped.
    // 88 ether WBTC => 44 USDC
    // 88 ether WETH => 44 USDC
    // 88 ether WMATIC => 44 USDC
    // Deduct 10 ether for referral: 132 - 10 = 122 ether
    // Total: 122 ether USDC
    // 122 ether USDC will be distributed to each rewarder proportionally 75%/25%.
    uint256 totalReward = 122 ether;
    assertEq(
      mockUSDC.balanceOf(address(plpStakingProtocolRevenueRewarder)),
      (totalReward * 75) / 100
    );
    assertEq(
      mockUSDC.balanceOf(address(dragonStakingProtocolRevenueRewarder)),
      (totalReward * 25) / 100
    );
    assertEq(mockUSDC.balanceOf(address(merkleAirdrop)), totalTokenAmount);
  }

  function testCorrectness_WhenBadMerkleAirdrop() external {
    address[] memory tokens = new address[](3);
    tokens[0] = address(wBtc);
    tokens[1] = address(wEth);
    tokens[2] = address(wMatic);

    vm.expectRevert();
    rewardDistributor.claimAndFeedProtocolRevenue(
      tokens,
      block.timestamp + 3 days,
      block.timestamp,
      1 ether,
      merkleRoot
    );
  }
}
