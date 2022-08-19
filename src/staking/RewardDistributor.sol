pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPool } from "../interfaces/IPool.sol";
import { IFeedableRewarder } from "../staking/interfaces/IFeedableRewarder.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract RewardDistributor is Ownable {
  using SafeERC20 for IERC20;

  address distributor;
  address public rewardToken;
  IPool public pool;
  IFeedableRewarder public feedableRewarder;

  constructor(
    address rewardToken_,
    IPool pool_,
    IFeedableRewarder feedableRewarder_
  ) {
    rewardToken = rewardToken_;
    pool = pool_;
    feedableRewarder = feedableRewarder_;
    distributor = msg.sender;
  }

  modifier onlyDistributor() {
    require(msg.sender == distributor);
    _;
  }

  // Do Swap List of Token to native token
  function distributeToken(address[] calldata tokenlist)
    external
    onlyDistributor
    onlyOwner
  {
    for (uint256 index = 0; index < tokenlist.length; index++) {
      // Approve inToken
      IERC20(tokenlist[index]).approve(
        address(pool),
        IERC20(tokenlist[index]).balanceOf(address(this))
      );

      // Swap to native token
      pool.swap(
        tokenlist[index],
        rewardToken,
        IERC20(tokenlist[index]).balanceOf(address(this)),
        0,
        address(this)
      );
    }
  }

  // Feed to FeedableRewarder contract
  function feedToRewarder(uint256 duration) external onlyDistributor onlyOwner {
    // Approve to feed inToken
    IERC20(rewardToken).approve(
      address(feedableRewarder),
      IERC20(rewardToken).balanceOf(address(this))
    );

    feedableRewarder.feed(
      IERC20(rewardToken).balanceOf(address(this)),
      duration
    );
  }
}
