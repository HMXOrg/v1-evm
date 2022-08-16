pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IRewarder } from "./interfaces/IRewarder.sol";
import { IStaking } from "./interfaces/IStaking.sol";

contract Rewarder is IRewarder {
  using SafeCast for uint256;
  using SafeCast for uint128;
  using SafeCast for int256;
  using SafeERC20 for IERC20;

  string public name;
  address public rewardToken;
  address public staking;

  // user address => reward debt
  mapping(address => int256) public userRewardDebts;

  // Reward calculation parameters
  uint64 public lastRewardTime;
  uint128 public accRewardPerShare;
  uint256 public rewardRate;
  uint256 public rewardRateExpiredAt;
  uint256 private constant ACC_REWARD_PRECISION = 1e12;

  // Events
  event LogOnDeposit(address indexed user, uint256 shareAmount);
  event LogOnWithdraw(address indexed user, uint256 shareAmount);
  event LogHarvest(address indexed user, uint256 pendingRewardAmount);
  event LogUpdateRewardCalculationParams(
    uint64 lastRewardTime,
    uint256 totalShareAmount,
    uint256 accRewardPerShare
  );

  // Error
  error Rewarder_rewardRateHasNotExpired();

  constructor(
    string memory name_,
    address rewardToken_,
    address staking_
  ) {
    // Sanity check
    IERC20(rewardToken_).totalSupply();
    IStaking(staking_).isRewarder(address(this));

    name = name_;
    rewardToken = rewardToken_;
    staking = staking_;
    lastRewardTime = block.timestamp.toUint64();
  }

  function onDeposit(address user, uint256 shareAmount) external {
    _updateRewardCalculationParams();

    userRewardDebts[user] =
      userRewardDebts[user] +
      ((shareAmount * accRewardPerShare) / ACC_REWARD_PRECISION).toInt256();

    emit LogOnDeposit(user, shareAmount);
  }

  function onWithdraw(address user, uint256 shareAmount) external {
    _updateRewardCalculationParams();

    userRewardDebts[user] =
      userRewardDebts[user] -
      ((shareAmount * accRewardPerShare) / ACC_REWARD_PRECISION).toInt256();

    emit LogOnWithdraw(user, shareAmount);
  }

  function onHarvest(address user) external {
    _updateRewardCalculationParams();

    int256 accumulatedRewards = ((_userShare(user) * accRewardPerShare) /
      ACC_REWARD_PRECISION).toInt256();
    uint256 pendingRewardAmount = (accumulatedRewards - userRewardDebts[user])
      .toUint256();

    userRewardDebts[user] = accumulatedRewards;

    if (pendingRewardAmount != 0) {
      IERC20(rewardToken).safeTransfer(user, pendingRewardAmount);
    }

    emit LogHarvest(user, pendingRewardAmount);
  }

  function feed(uint256 feedAmount, uint256 periodInSecond) external {
    if (block.timestamp < rewardRateExpiredAt)
      revert Rewarder_rewardRateHasNotExpired();

    _updateRewardCalculationParams();
    IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), feedAmount);
    rewardRate = feedAmount / periodInSecond;
    rewardRateExpiredAt = block.timestamp + periodInSecond;
  }

  function _updateRewardCalculationParams() internal {
    uint256 totalShare = _totalShare();
    if (block.timestamp > lastRewardTime) {
      if (totalShare > 0) {
        uint256 _rewards = _timePast() * rewardRate;

        accRewardPerShare =
          accRewardPerShare +
          ((_rewards * ACC_REWARD_PRECISION) / totalShare).toUint128();
      }

      lastRewardTime = block.timestamp.toUint64();
      emit LogUpdateRewardCalculationParams(
        lastRewardTime,
        totalShare,
        accRewardPerShare
      );
    }
  }

  function _timePast() private view returns (uint256) {
    if (block.timestamp < rewardRateExpiredAt) {
      return block.timestamp - lastRewardTime;
    } else {
      return rewardRateExpiredAt - lastRewardTime;
    }
  }

  function _totalShare() private view returns (uint256) {
    return IStaking(staking).calculateTotalShare(address(this));
  }

  function _userShare(address user) private view returns (uint256) {
    return IStaking(staking).calculateShare(address(this), user);
  }
}
