pragma solidity 0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IFeedableRewarder } from "../staking/interfaces/IFeedableRewarder.sol";
import { IPoolRouter } from "../interfaces/IPoolRouter.sol";
import { AdminFacetInterface } from "../core/pool-diamond/interfaces/AdminFacetInterface.sol";
import { GetterFacetInterface } from "../core/pool-diamond/interfaces/GetterFacetInterface.sol";

contract RewardDistributor is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev token addreses
  address public rewardToken;

  /// @dev pool and its companion addresses
  address public pool;
  address public poolRouter;
  address public plpStakingProtocolRevenueRewarder;
  address public dragonStakingProtocolRevenueRewarder;

  /// @dev Distribution weight
  /// max bps = 10000
  uint256 public devFundBps;
  uint256 public plpStakingBps; // dragonStakingBps will be assumed as 10000 - plpStakingBps

  /// @dev Fund addresses
  address public devFundAddress;

  function initialize(
    address rewardToken_,
    address pool_,
    address plpStakingProtocolRevenueRewarder_,
    address dragonStakingProtocolRevenueRewarder_,
    uint256 devFundBps_,
    uint256 plpStakingBps_,
    address devFundAddress_
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    rewardToken = rewardToken_;
    pool = pool_;
    plpStakingProtocolRevenueRewarder = plpStakingProtocolRevenueRewarder_;
    dragonStakingProtocolRevenueRewarder = dragonStakingProtocolRevenueRewarder_;
    devFundBps = devFundBps_;
    plpStakingBps = plpStakingBps_;
    devFundAddress = devFundAddress_;
  }

  function claimAndFeedProtocolRevenue(
    address[] memory tokens,
    uint256 feedingExpiredAt
  ) external {
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; ) {
      address token = tokens[0];

      // 1. Withdraw protocol revenue
      _withdrawProtocolRevenue(token);

      // 2. Collect dev fund
      _collectDevFund(token);

      // 3. Swap those revenue (along with surplus) to RewardToken Token
      _swapTokenToRewardToken(
        token,
        IERC20Upgradeable(token).balanceOf(address(this))
      );

      unchecked {
        i++;
      }
    }

    // At this point, we got a portion of RewardToken token.
    // 4. Feed reward to both rewarders
    _feedRewardToRewarders(feedingExpiredAt);
  }

  function _withdrawProtocolRevenue(address token) internal {
    // Withdraw the all max amount revenue from the pool
    AdminFacetInterface(pool).withdrawFeeReserve(
      token,
      address(this),
      GetterFacetInterface(pool).feeReserveOf(token)
    );
  }

  function _collectDevFund(address token) internal {
    uint256 collectingAmount = (IERC20Upgradeable(token).balanceOf(
      address(this)
    ) * devFundBps) / 10000;

    // If no token, no need transfer
    if (collectingAmount == 0) return;

    IERC20Upgradeable(token).transfer(devFundAddress, collectingAmount);
  }

  function _swapTokenToRewardToken(address token, uint256 amount) internal {
    // If no token, no need to swap
    if (amount == 0) return;

    // If token is already reward token, no need to swap
    if (token == rewardToken) return;

    // Approve the token
    IERC20Upgradeable(token).approve(pool, amount);

    // Swap
    IPoolRouter(poolRouter).swap(
      pool,
      token,
      rewardToken,
      amount,
      0,
      address(this)
    );
  }

  function _feedRewardToRewarders(uint256 feedingExpiredAt) internal {
    uint256 totalRewardAmount = IERC20Upgradeable(rewardToken).balanceOf(
      address(this)
    );

    uint256 plpStakingRewardAmount = (totalRewardAmount * plpStakingBps) /
      10000;
    uint256 dragonStakingRewardAmount = totalRewardAmount -
      plpStakingRewardAmount;

    // Approve and feed to PLPStaking
    IERC20Upgradeable(rewardToken).approve(
      plpStakingProtocolRevenueRewarder,
      plpStakingRewardAmount
    );
    IFeedableRewarder(plpStakingProtocolRevenueRewarder).feedWithExpiredAt(
      plpStakingRewardAmount,
      feedingExpiredAt
    );

    // Approve and feed to DragonStaking
    IERC20Upgradeable(rewardToken).approve(
      dragonStakingProtocolRevenueRewarder,
      dragonStakingRewardAmount
    );
    IFeedableRewarder(dragonStakingProtocolRevenueRewarder).feedWithExpiredAt(
      dragonStakingRewardAmount,
      feedingExpiredAt
    );
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
