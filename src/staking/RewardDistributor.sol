pragma solidity 0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IFeedableRewarder } from "../staking/interfaces/IFeedableRewarder.sol";
import { IPoolRouter } from "../interfaces/IPoolRouter.sol";
import { AdminFacetInterface } from "../core/pool-diamond/interfaces/AdminFacetInterface.sol";
import { GetterFacetInterface } from "../core/pool-diamond/interfaces/GetterFacetInterface.sol";
import { MerkleAirdropFactory } from "../airdrop/MerkleAirdropFactory.sol";
import { MerkleAirdrop } from "../airdrop/MerkleAirdrop.sol";

contract RewardDistributor is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev Token addreses
  address public rewardToken; // the token to be fed to rewarder

  /// @dev Pool and its companion addresses
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

  MerkleAirdropFactory public merkleAirdropFactory;
  address public merkleAirdropTemplate;

  uint256 public referralRevenueMaxThreshold; // in BPS (10000)

  /// @dev Error
  error RewardDistributor_BadParams();
  error RewardDistributor_BadReferralRevenueMaxThreshold();
  error RewardDistributor_BadMerkleAirdrop(
    bytes32 merkleRoote,
    bytes32 salt,
    address merkleAirdropAddress
  );
  error RewardDistributor_ReferralRevenueExceedMaxThreshold();

  /// @dev Events
  event LogSetParams(
    address rewardToken,
    address pool,
    address poolRouter,
    address plpStakingProtocolRevenueRewarder,
    address dragonStakingProtocolRevenueRewarder,
    uint256 devFundBps,
    uint256 plpStakingBps,
    address devFundAddress,
    address merkleAirdropFactory,
    address merkleAirdropTemplate
  );
  event LogSetReferralRevenueMaxThreshold(
    uint256 oldThreshold,
    uint256 newThreshold
  );

  function initialize(
    address rewardToken_,
    address pool_,
    address poolRouter_,
    address plpStakingProtocolRevenueRewarder_,
    address dragonStakingProtocolRevenueRewarder_,
    uint256 devFundBps_,
    uint256 plpStakingBps_,
    address devFundAddress_,
    MerkleAirdropFactory merkleAirdropFactory_,
    address merkleAirdropTemplate_,
    uint256 referralRevenueMaxThreshold_
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    rewardToken = rewardToken_;
    pool = pool_;
    poolRouter = poolRouter_;
    plpStakingProtocolRevenueRewarder = plpStakingProtocolRevenueRewarder_;
    dragonStakingProtocolRevenueRewarder = dragonStakingProtocolRevenueRewarder_;
    devFundBps = devFundBps_;
    plpStakingBps = plpStakingBps_;
    devFundAddress = devFundAddress_;
    merkleAirdropFactory = merkleAirdropFactory_;
    merkleAirdropTemplate = merkleAirdropTemplate_;

    referralRevenueMaxThreshold = referralRevenueMaxThreshold_;
  }

  function setParams(
    address rewardToken_,
    address pool_,
    address poolRouter_,
    address plpStakingProtocolRevenueRewarder_,
    address dragonStakingProtocolRevenueRewarder_,
    uint256 devFundBps_,
    uint256 plpStakingBps_,
    address devFundAddress_,
    MerkleAirdropFactory merkleAirdropFactory_,
    address merkleAirdropTemplate_
  ) external onlyOwner {
    if (plpStakingBps_ > 10000) revert RewardDistributor_BadParams();

    rewardToken = rewardToken_;
    pool = pool_;
    poolRouter = poolRouter_;
    plpStakingProtocolRevenueRewarder = plpStakingProtocolRevenueRewarder_;
    dragonStakingProtocolRevenueRewarder = dragonStakingProtocolRevenueRewarder_;
    devFundBps = devFundBps_;
    plpStakingBps = plpStakingBps_;
    devFundAddress = devFundAddress_;
    merkleAirdropFactory = merkleAirdropFactory_;
    merkleAirdropTemplate = merkleAirdropTemplate_;

    emit LogSetParams(
      rewardToken_,
      pool_,
      poolRouter_,
      plpStakingProtocolRevenueRewarder_,
      dragonStakingProtocolRevenueRewarder_,
      devFundBps_,
      plpStakingBps_,
      devFundAddress_,
      address(merkleAirdropFactory_),
      merkleAirdropTemplate_
    );
  }

  function setReferralRevenueMaxThreshold(
    uint256 newReferralRevenueMaxThreshold
  ) external onlyOwner {
    if (newReferralRevenueMaxThreshold > 5000) {
      // should not exceed 50% of total revenue
      revert RewardDistributor_BadReferralRevenueMaxThreshold();
    }
    emit LogSetReferralRevenueMaxThreshold(
      referralRevenueMaxThreshold,
      newReferralRevenueMaxThreshold
    );
    referralRevenueMaxThreshold = newReferralRevenueMaxThreshold;
  }

  function claimAndSwap(address[] memory tokens) external {
    _claimAndSwap(tokens);
  }

  function _claimAndSwap(address[] memory tokens) internal {
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; ) {
      _withdrawProtocolRevenue(tokens[i]);

      unchecked {
        i++;
      }
    }

    for (uint256 i = 0; i < length; ) {
      _swapTokenToRewardToken(
        tokens[i],
        IERC20Upgradeable(tokens[i]).balanceOf(address(this))
      );

      unchecked {
        i++;
      }
    }
  }

  function claimAndFeedProtocolRevenue(
    address[] memory tokens,
    uint256 feedingExpiredAt,
    uint256 weekTimestamp,
    uint256 referralRevenueAmount,
    bytes32 merkleRoot
  ) external {
    bytes32 salt = keccak256(abi.encode(weekTimestamp, referralRevenueAmount));
    address merkleAirdropAddress = merkleAirdropFactory
      .computeMerkleAirdropAddress(merkleAirdropTemplate, salt);
    if (MerkleAirdrop(merkleAirdropAddress).merkleRoot() != merkleRoot)
      revert RewardDistributor_BadMerkleAirdrop(
        merkleRoot,
        salt,
        merkleAirdropAddress
      );

    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; ) {
      // 1. Withdraw protocol revenue
      _withdrawProtocolRevenue(tokens[i]);

      // 2. Collect dev fund
      _collectDevFund(tokens[i]);

      unchecked {
        i++;
      }
    }

    // Note: We need to seprate this loop from another loop, since if we have the input token
    // the same token as reward token, in our case WMatic, we could end up in overcollecting
    // dev fund.
    // The reason is that we `_collectDevFund()` as input token and then `_swapTokenToRewardToken`,
    // on the next loop with reward token as input token, the claimed revenue would get mixed up.
    for (uint256 i = 0; i < length; ) {
      // 3. Swap those revenue (along with surplus) to RewardToken Token
      _swapTokenToRewardToken(
        tokens[i],
        IERC20Upgradeable(tokens[i]).balanceOf(address(this))
      );

      unchecked {
        i++;
      }
    }

    // 4. Transfer referral revenue to merkle airdrop address for distribution
    uint256 totalProtocolRevenue = IERC20Upgradeable(rewardToken).balanceOf(
      address(this)
    );
    // totalProtocolRevenue * referralRevenueMaxThreshold / 10000 < referralRevenueAmount
    if (
      totalProtocolRevenue * referralRevenueMaxThreshold <
      referralRevenueAmount * 10000
    ) revert RewardDistributor_ReferralRevenueExceedMaxThreshold();
    IERC20Upgradeable(rewardToken).safeTransfer(
      merkleAirdropAddress,
      referralRevenueAmount
    );

    // At this point, we got a portion of reward tokens for protocol revenue.
    // 5. Feed reward to both rewarders
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
    IERC20Upgradeable(token).approve(poolRouter, amount);

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
