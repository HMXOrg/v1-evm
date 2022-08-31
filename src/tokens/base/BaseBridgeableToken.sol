// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IBridgeStrategy } from "../../interfaces/IBridgeStrategy.sol";
import { BaseMintableToken } from "./BaseMintableToken.sol";

contract BaseBridgeableToken is BaseMintableToken {
  mapping(address => bool) public bridgeStrategies;

  error BaseBridgeableToken_BadStrategy();

  constructor(
    string memory name,
    string memory symbol,
    uint8 __decimals
  ) BaseMintableToken(name, symbol, __decimals) {}

  function bridgeToken(
    uint256 destinationChainId,
    address destinationAddress,
    uint256 amount,
    address bridgeStrategy,
    bytes memory payload
  ) external payable {
    // Validate bridgeStrategy
    if (!bridgeStrategies[bridgeStrategy])
      revert BaseBridgeableToken_BadStrategy();

    // Burn token from user
    _burn(msg.sender, amount);

    // Execute bridge strategy
    IBridgeStrategy(bridgeStrategy).execute(
      msg.sender,
      destinationChainId,
      destinationAddress,
      amount,
      payload
    );
  }
}
