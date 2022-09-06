// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IRewarder.sol";
import "./interfaces/IStaking.sol";
import "../tokens/DragonPoint.sol";

contract DragonStaking is IStaking, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  error DragonStaking_UnknownStakingToken();
  error DragonStaking_InsufficientTokenAmount();
  error DragonStaking_NotRewarder();
  error DragonStaking_NotCompounder();

  mapping(address => mapping(address => uint256)) public userTokenAmount;
  mapping(address => bool) public isRewarder;
  mapping(address => bool) public isStakingToken;
  mapping(address => address[]) public stakingTokenRewarders;
  mapping(address => address[]) public rewarderStakingTokens;

  address public compounder;

  DragonPoint public dp;
  IRewarder public dragonPointRewarder;

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

  function initialize(address dp_) external initializer {
    OwnableUpgradeable.__Ownable_init();

    dp = DragonPoint(dp_);
  }

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
    if (!isStakingToken[token]) revert DragonStaking_UnknownStakingToken();

    uint256 length = stakingTokenRewarders[token].length;
    for (uint256 i = 0; i < length; ) {
      address rewarder = stakingTokenRewarders[token][i];

      IRewarder(rewarder).onDeposit(to, amount);

      unchecked {
        ++i;
      }
    }

    userTokenAmount[token][to] += amount;
    IERC20Upgradeable(token).safeTransferFrom(
      msg.sender,
      address(this),
      amount
    );

    emit LogDeposit(msg.sender, to, token, amount);
  }

  function getUserTokenAmount(address token, address sender)
    external
    view
    returns (uint256)
  {
    return userTokenAmount[token][sender];
  }

  function getStakingTokenRewarders(address token)
    external
    view
    returns (address[] memory)
  {
    return stakingTokenRewarders[token];
  }

  function withdraw(
    address to,
    address token,
    uint256 amount
  ) external {
    _withdraw(to, token, amount);
    _afterWithdraw(to, token, amount);
    emit LogWithdraw(msg.sender, to, token, amount);
  }

  function _withdraw(
    address to,
    address token,
    uint256 amount
  ) internal {
    if (!isStakingToken[token]) revert DragonStaking_UnknownStakingToken();
    if (userTokenAmount[token][to] < amount)
      revert DragonStaking_InsufficientTokenAmount();

    uint256 length = stakingTokenRewarders[token].length;
    for (uint256 i = 0; i < length; ) {
      address rewarder = stakingTokenRewarders[token][i];

      IRewarder(rewarder).onWithdraw(to, amount);

      unchecked {
        ++i;
      }
    }
    userTokenAmount[token][to] -= amount;
    IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    emit LogWithdraw(msg.sender, to, token, amount);
  }

  function _afterWithdraw(
    address to,
    address,
    uint256
  ) internal {
    _withdraw(to, address(dp), userTokenAmount[address(dp)][to]);

    dp.burn(to, dp.balanceOf(to));
    dragonPointRewarder.onWithdraw(to, 0);
  }

  function harvest(address[] memory rewarders) external {
    _harvestFor(msg.sender, msg.sender, rewarders);
  }

  function harvestToCompounder(address user, address[] memory rewarders)
    external
  {
    if (compounder != msg.sender) revert DragonStaking_NotCompounder();
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
        revert DragonStaking_NotRewarder();
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
      totalShare += IERC20Upgradeable(tokens[i]).balanceOf(address(this));

      unchecked {
        ++i;
      }
    }
    return totalShare;
  }

  function setDragonPointRewarder(address rewarder) external onlyOwner {
    dragonPointRewarder = IRewarder(rewarder);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
