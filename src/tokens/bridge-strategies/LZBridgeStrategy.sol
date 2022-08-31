// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IBridgeStrategy } from "../../interfaces/IBridgeStrategy.sol";
import { ILayerZeroEndpoint } from "../../interfaces/ILayerZeroEndpoint.sol";

contract LZBridgeStrategy is IBridgeStrategy {
  error LZBridgeStrategy_UnknownChainId();

  ILayerZeroEndpoint public lzEndpoint;
  mapping(uint256 => address) destinationTokenContracts;

  function execute(
    address caller,
    uint256 destinationChainId,
    address tokenRecipient,
    uint256 amount,
    bytes memory _payload
  ) external payable {
    address destinationTokenContract = destinationTokenContracts[
      destinationChainId
    ];
    if (destinationTokenContract == address(0))
      revert LZBridgeStrategy_UnknownChainId();

    bytes memory payload = abi.encode(tokenRecipient, amount);

    lzEndpoint.send{ value: msg.value }(
      uint16(destinationChainId),
      abi.encode(destinationTokenContract),
      payload,
      payable(caller),
      address(0),
      abi.encode(0)
    );
  }
}
