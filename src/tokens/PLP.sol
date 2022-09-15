// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PLP is ERC20Upgradeable, OwnableUpgradeable {
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public cooldown;
  mapping(address => bool) public isMinter;

  event PLP_SetMinter(address oldMinter, address newMinter);
  event PLP_SetWhitelist(address whitelisted, bool isActive);
  event PLP_SetMinter(address minter, bool prevAllow, bool newAllow);

  error PLP_BadCooldownExpireAt(
    uint256 cooldownExpireAt,
    uint256 blockTimestamp
  );
  error PLP_Cooldown(uint256 cooldownExpireAt);
  error PLP_isNotTransferrer();
  error PLP_NotMinter();

  modifier onlyMinter() {
    if (!isMinter[msg.sender]) revert PLP_NotMinter();
    _;
  }

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    ERC20Upgradeable.__ERC20_init("P88 Liquidity Provider", "PLP");
  }

  function setWhitelist(address whitelisted, bool isActive) external onlyOwner {
    whitelist[whitelisted] = isActive;

    emit PLP_SetWhitelist(whitelisted, isActive);
  }

  function setMinter(address minter, bool allow) external onlyOwner {
    isMinter[minter] = allow;
    emit PLP_SetMinter(minter, isMinter[minter], allow);
  }

  function mint(
    address to,
    uint256 amount,
    uint256 cooldownExpireAt
  ) public onlyMinter {
    if (cooldownExpireAt < block.timestamp)
      revert PLP_BadCooldownExpireAt(cooldownExpireAt, block.timestamp);
    cooldown[to] = cooldownExpireAt;
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public onlyMinter {
    _burn(from, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    uint256 cooldownExpireAt = cooldown[from];
    if (
      (amount > 0 && !whitelist[from] && !whitelist[to]) &&
      block.timestamp < cooldownExpireAt
    ) revert PLP_Cooldown(cooldownExpireAt);
  }
}
