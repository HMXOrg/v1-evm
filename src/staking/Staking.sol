// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IRewarder.sol";
import "./interfaces/IStaking.sol";

contract Staking is IStaking, Ownable {
  using SafeERC20 for IERC20;

  error Staking_isNotStakingToken();
  error Staking_Insufficient();

  mapping(address => mapping(address => uint256)) public userTokenAmount;
  address[] public rewarders;
  mapping(address => bool) public isRewarder;
  mapping(address => bool) public isStakingToken;
  mapping(address => address[]) public stakingTokenRewarders;
  mapping(address => address[]) public rewarderStakingTokens;

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
    public
    onlyOwner
  {
    for (uint256 i = 0; i < newRewarders.length; i++) {
      _updatePool(newToken, newRewarders[i]);
    }
  }

  function addRewarder(address newRewarder, address[] memory newTokens)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < newTokens.length; i++) {
      _updatePool(newTokens[i], newRewarder);
    }
  }

  function _updatePool(address newToken, address newRewarder) internal {
    stakingTokenRewarders[newToken].push(newRewarder);
    rewarderStakingTokens[newRewarder].push(newToken);
    isStakingToken[newToken] = true;
    if (!isRewarder[newRewarder]) {
      isRewarder[newRewarder] = true;
      rewarders.push(newRewarder);
    }
  }

  function deposit(
    address to,
    address token,
    uint256 amount
  ) external {
    if (!isStakingToken[token]) revert Staking_isNotStakingToken();

    uint256 length = stakingTokenRewarders[token].length;
    for (uint256 i = 0; i < length; i++) {
      address rewarder = stakingTokenRewarders[token][i];

      IRewarder(rewarder).onDeposit(to, amount);
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
    if (!isStakingToken[token]) revert Staking_isNotStakingToken();
    if (userTokenAmount[token][to] < amount) revert Staking_Insufficient();

    uint256 length = stakingTokenRewarders[token].length;
    for (uint256 i = 0; i < length; i++) {
      address rewarder = stakingTokenRewarders[token][i];

      IRewarder(rewarder).onWithdraw(to, amount);
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

  function harvest() external {
    uint256 length = rewarders.length;
    for (uint256 i = 0; i < length; i++) {
      IRewarder(rewarders[i]).onHarvest(msg.sender);
    }
  }

  function calculateShare(address rewarder, address user)
    public
    view
    returns (uint256)
  {
    address[] memory tokens = rewarderStakingTokens[rewarder];
    uint256 share = 0;
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; i++) {
      share += userTokenAmount[tokens[i]][user];
    }
    return share;
  }

  function calculateTotalShare(address rewarder) public view returns (uint256) {
    address[] memory tokens = rewarderStakingTokens[rewarder];
    uint256 totalShare = 0;
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; i++) {
      totalShare += IERC20(tokens[i]).balanceOf(address(this));
    }
    return totalShare;
  }
}
