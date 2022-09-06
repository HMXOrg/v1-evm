pragma solidity 0.8.16;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IPool } from "../interfaces/IPool.sol";
import { IFeedableRewarder } from "../staking/interfaces/IFeedableRewarder.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RewardDistributor is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  address public rewardToken;
  IPool public pool;
  IFeedableRewarder public feedableRewarder;

  function initialize(
    address rewardToken_,
    IPool pool_,
    IFeedableRewarder feedableRewarder_
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    rewardToken = rewardToken_;
    pool = pool_;
    feedableRewarder = feedableRewarder_;
  }

  // Do Swap List of Token to native token
  function distributeToken(address[] calldata tokenlist) external onlyOwner {
    uint256 length = tokenlist.length;
    for (uint256 index = 0; index < length; ) {
      uint256 tokenAmount = IERC20Upgradeable(tokenlist[index]).balanceOf(
        address(this)
      );

      // Approve inToken
      IERC20Upgradeable(tokenlist[index]).approve(address(pool), tokenAmount);

      // Swap to native token
      pool.swap(tokenlist[index], rewardToken, tokenAmount, 0, address(this));

      unchecked {
        ++index;
      }
    }
  }

  // Feed to FeedableRewarder contract
  function feedToRewarder(uint256 duration) external onlyOwner {
    uint256 rewardTokenAmount = IERC20Upgradeable(rewardToken).balanceOf(
      address(this)
    );

    // Approve to feed inToken
    IERC20Upgradeable(rewardToken).approve(
      address(feedableRewarder),
      rewardTokenAmount
    );

    feedableRewarder.feed(rewardTokenAmount, duration);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
