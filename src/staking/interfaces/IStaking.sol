pragma solidity 0.8.14;

interface IStaking {
  function deposit(
    address to,
    address token,
    uint256 amount
  ) external;

  function withdraw(
    address to,
    address token,
    uint256 amount
  ) external;

  function harvest(address[] memory rewarders) external;

  function harvestToCompounder(address user, address[] memory rewarders)
    external;

  function calculateTotalShare(address rewarder)
    external
    view
    returns (uint256);

  function calculateShare(address rewarder, address user)
    external
    view
    returns (uint256);

  function isRewarder(address rewarder) external view returns (bool);
}
