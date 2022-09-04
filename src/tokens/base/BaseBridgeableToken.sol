// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IBridgeStrategy } from "../../interfaces/IBridgeStrategy.sol";
import { BaseMintableToken } from "./BaseMintableToken.sol";

contract BaseBridgeableToken is BaseMintableToken {
  mapping(address => bool) public bridgeStrategies;
  bool public isBurnAndMint;
  mapping(address => bool) isBridge;

  error BaseBridgeableToken_BadStrategy();
  error BaseBridgeableToken_BadBridge();

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 __decimals,
    uint256 maxSupply_,
    bool isBurnAndMint_
  ) BaseMintableToken(name_, symbol_, __decimals, maxSupply_) {
    isBurnAndMint = isBurnAndMint_;
  }

  modifier onlyBridge() {
    if (!isBridge[msg.sender]) revert BaseBridgeableToken_BadBridge();
    _;
  }

  function bridgeToken(
    uint256 destinationChainId,
    address tokenRecipient,
    uint256 amount,
    address bridgeStrategy,
    bytes memory payload
  ) external payable {
    // Validate bridgeStrategy
    if (!bridgeStrategies[bridgeStrategy])
      revert BaseBridgeableToken_BadStrategy();

    // Burn token from user
    if (isBurnAndMint) _burn(msg.sender, amount);
    else _transfer(msg.sender, address(this), amount);

    // Execute bridge strategy
    IBridgeStrategy(bridgeStrategy).execute(
      msg.sender,
      destinationChainId,
      tokenRecipient,
      amount,
      payload
    );
  }

  function setBridgeStrategy(address strategy_, bool active_)
    external
    onlyOwner
  {
    bridgeStrategies[strategy_] = active_;
  }

  function setBridge(address bridge_, bool active_) external onlyOwner {
    isBridge[bridge_] = active_;
  }

  function mintFromBridge(address to_, uint256 amount_) public onlyBridge {
    if (!isBurnAndMint) {
      _transfer(address(this), to_, amount_);
    } else {
      _mint(to_, amount_);
    }
  }
}
