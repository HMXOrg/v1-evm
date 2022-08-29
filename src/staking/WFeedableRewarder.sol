pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IRewarder } from "./interfaces/IRewarder.sol";
import { IStaking } from "./interfaces/IStaking.sol";
import { IWNative } from "../interfaces/IWNative.sol";
import { FeedableRewarder } from "./FeedableRewarder.sol";

contract WFeedableRewarder is FeedableRewarder {
  using SafeERC20 for IERC20;

  error WFeedableRewarder_TransferFail();

  function initialize(
    string memory name_,
    address rewardToken_,
    address staking_
  ) external override initializer {
    __FeedableRewarder_init_unchained(name_, rewardToken_, staking_);

    // Sanity check. Ensure that the rewardToken is wrappable.
    IWNative(rewardToken).deposit{ value: 0 }();
  }

  function _harvestToken(address receiver, uint256 pendingRewardAmount)
    internal
    override
  {
    // unwrap
    IWNative(rewardToken).withdraw(pendingRewardAmount);

    // transfer native token
    payable(receiver).transfer(pendingRewardAmount);
  }

  receive() external payable {}

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
