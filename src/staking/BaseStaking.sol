// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IRewarder.sol";
import "./interfaces/IStaking.sol";

abstract contract BaseStaking is IStaking, Ownable {
  using SafeERC20 for IERC20;

  error Staking_UnknownStakingToken();
  error Staking_InsufficientTokenAmount();
  error Staking_NotRewarder();
  error Staking_NotCompounder();

  mapping(address => mapping(address => uint256)) public userTokenAmount;
  mapping(address => bool) public isRewarder;
  mapping(address => bool) public isStakingToken;
  mapping(address => address[]) public stakingTokenRewarders;
  mapping(address => address[]) public rewarderStakingTokens;

  address public compounder;

  event LogDeposit(
    address indexed caller,
    address indexed user,
    address token,
    uint256 amount
  );
  event LogWithdraw(
    address indexed caller,
    address indexed user,
    address token,
    uint256 amount
  );

  function addStakingToken(address newToken, address[] memory newRewarders)
    external
    onlyOwner
  {
    uint256 length = newRewarders.length;
    for (uint256 i = 0; i < length; ) {
      _updatePool(newToken, newRewarders[i]);

      unchecked {
        ++i;
      }
    }
  }

  function addRewarder(address newRewarder, address[] memory newTokens)
    external
    onlyOwner
  {
    uint256 length = newTokens.length;
    for (uint256 i = 0; i < length; ) {
      _updatePool(newTokens[i], newRewarder);

      unchecked {
        ++i;
      }
    }
  }

  function _updatePool(address newToken, address newRewarder) internal {
    stakingTokenRewarders[newToken].push(newRewarder);
    rewarderStakingTokens[newRewarder].push(newToken);
    isStakingToken[newToken] = true;
    if (!isRewarder[newRewarder]) {
      isRewarder[newRewarder] = true;
    }
  }

  function setCompounder(address compounder_) external onlyOwner {
    compounder = compounder_;
  }

  function deposit(
    address to,
    address token,
    uint256 amount
  ) external {
    if (!isStakingToken[token]) revert Staking_UnknownStakingToken();

    uint256 length = stakingTokenRewarders[token].length;
    for (uint256 i = 0; i < length; ) {
      address rewarder = stakingTokenRewarders[token][i];

      IRewarder(rewarder).onDeposit(to, amount);

      unchecked {
        ++i;
      }
    }

    userTokenAmount[token][to] += amount;
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    emit LogDeposit(msg.sender, to, token, amount);
  }

  function withdraw(
    address to,
    address token,
    uint256 amount
  ) external {
    if (!isStakingToken[token]) revert Staking_UnknownStakingToken();
    if (userTokenAmount[token][to] < amount)
      revert Staking_InsufficientTokenAmount();

    uint256 length = stakingTokenRewarders[token].length;
    for (uint256 i = 0; i < length; ) {
      address rewarder = stakingTokenRewarders[token][i];

      IRewarder(rewarder).onWithdraw(to, amount);

      unchecked {
        ++i;
      }
    }

    userTokenAmount[token][to] -= amount;
    IERC20(token).safeTransfer(msg.sender, amount);

    _afterWithdraw(to, token, amount);

    emit LogWithdraw(msg.sender, to, token, amount);
  }

  function _afterWithdraw(
    address to,
    address token,
    uint256 amount
  ) internal virtual {}

  function harvest(address[] memory rewarders) external {
    _harvestFor(msg.sender, msg.sender, rewarders);
  }

  function harvestToCompounder(address user, address[] memory rewarders)
    external
  {
    if (compounder != msg.sender) revert Staking_NotCompounder();
    _harvestFor(user, compounder, rewarders);
  }

  function _harvestFor(
    address user,
    address receiver,
    address[] memory rewarders
  ) internal {
    uint256 length = rewarders.length;
    for (uint256 i = 0; i < length; ) {
      if (!isRewarder[rewarders[i]]) {
        revert Staking_NotRewarder();
      }

      IRewarder(rewarders[i]).onHarvest(user, receiver);

      unchecked {
        ++i;
      }
    }
  }

  function calculateShare(address rewarder, address user)
    external
    view
    returns (uint256)
  {
    address[] memory tokens = rewarderStakingTokens[rewarder];
    uint256 share = 0;
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; ) {
      share += userTokenAmount[tokens[i]][user];

      unchecked {
        ++i;
      }
    }
    return share;
  }

  function calculateTotalShare(address rewarder)
    external
    view
    returns (uint256)
  {
    address[] memory tokens = rewarderStakingTokens[rewarder];
    uint256 totalShare = 0;
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; ) {
      totalShare += IERC20(tokens[i]).balanceOf(address(this));

      unchecked {
        ++i;
      }
    }
    return totalShare;
  }
}
