pragma solidity 0.8.14;

interface IRewarder {
  function name() external view returns (string memory);

  function onDeposit(
    address user,
    uint256 shareAmount,
    uint256 totalShareAmount // exclude share amount
  ) external;

  function onWithdraw(
    address user,
    uint256 shareAmount,
    uint256 totalShareAmount // exclude share amount
  ) external;

  function onHarvest(
    address user,
    uint256 netUserShareAmount,
    uint256 totalShareAmount
  ) external;
}
