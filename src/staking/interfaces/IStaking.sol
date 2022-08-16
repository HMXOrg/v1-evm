pragma solidity 0.8.14;

interface IStaking {
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
