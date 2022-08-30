pragma solidity 0.8.16;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IRewarder } from "./interfaces/IRewarder.sol";
import { IStaking } from "./interfaces/IStaking.sol";
import { MintableTokenInterface } from "../interfaces/MintableTokenInterface.sol";

contract AdHocMintRewarder is IRewarder, OwnableUpgradeable {
  using SafeCast for uint256;
  using SafeCast for uint128;
  using SafeCast for int256;
  using SafeERC20 for IERC20;

  string public name;
  address public rewardToken;
  address public staking;

  // Reward calculation parameters
  uint64 constant YEAR = 365 days;
  mapping(address => uint64) public userLastRewards;
  mapping(address => uint256) public userAccRewards;

  // For compatability only, no calculation usage on chain
  uint256 public rewardRate = 31709791983 wei; // = 1 ether / 365 days

  // Events
  event LogOnDeposit(address indexed user, uint256 shareAmount);
  event LogOnWithdraw(address indexed user, uint256 shareAmount);
  event LogHarvest(address indexed user, uint256 pendingRewardAmount);

  // Error
  error AdHocMintRewarderError_NotStakingContract();

  modifier onlyStakingContract() {
    if (msg.sender != staking)
      revert AdHocMintRewarderError_NotStakingContract();
    _;
  }

  function initialize(
    string memory name_,
    address rewardToken_,
    address staking_
  ) external initializer {
    // Sanity check
    IERC20(rewardToken_).totalSupply();
    IStaking(staking_).isRewarder(address(this));
    name = name_;
    rewardToken = rewardToken_;
    staking = staking_;
  }

  function onDeposit(address user, uint256 shareAmount)
    external
    onlyStakingContract
  {
    // Accumulate user reward
    userAccRewards[user] += _calculateUserAccReward(user);
    userLastRewards[user] = block.timestamp.toUint64();
    emit LogOnDeposit(user, shareAmount);
  }

  function onWithdraw(address user, uint256 shareAmount)
    external
    onlyStakingContract
  {
    // Reset user reward
    // The rule is whenever withdraw occurs, no matter the size, reward calculation should restart.
    userAccRewards[user] = 0;
    userLastRewards[user] = block.timestamp.toUint64();
    emit LogOnWithdraw(user, shareAmount);
  }

  function onHarvest(address user, address receiver)
    external
    onlyStakingContract
  {
    uint256 pendingRewardAmount = _pendingReward(user);

    // Reset user reward accumulation.
    // The next action will start accum reward from zero again.
    userAccRewards[user] = 0;
    userLastRewards[user] = block.timestamp.toUint64();

    if (pendingRewardAmount != 0) {
      _harvestToken(receiver, pendingRewardAmount);
    }

    emit LogHarvest(user, pendingRewardAmount);
  }

  function pendingReward(address user) external view returns (uint256) {
    return _pendingReward(user);
  }

  function _pendingReward(address user) internal view returns (uint256) {
    // (accumulated reward since the last action) + (jotted reward from the past)
    return _calculateUserAccReward(user) + userAccRewards[user];
  }

  function _calculateUserAccReward(address user)
    internal
    view
    returns (uint256)
  {
    // [100% APR] If a user stake N shares for a year, he will be rewarded with N tokens.
    return
      ((block.timestamp - userLastRewards[user]) * _userShare(user)) / YEAR;
  }

  function _userShare(address user) private view returns (uint256) {
    return IStaking(staking).calculateShare(address(this), user);
  }

  function _harvestToken(address receiver, uint256 pendingRewardAmount)
    internal
    virtual
  {
    MintableTokenInterface(rewardToken).mint(receiver, pendingRewardAmount);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
