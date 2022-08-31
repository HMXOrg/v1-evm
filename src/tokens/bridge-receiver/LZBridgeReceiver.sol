// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MintableTokenInterface } from "../../interfaces/MintableTokenInterface.sol";

contract LZBridgeReceiver is Ownable {
  address public immutable lzEndpoint;
  MintableTokenInterface public token;
  mapping(uint16 => bytes) public trustedRemoteLookup;
  mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
    public failedMessages;

  event MessageFailed(
    uint16 _srcChainId,
    bytes _srcAddress,
    uint64 _nonce,
    bytes _payload
  );
  event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

  constructor(address _endpoint) {
    lzEndpoint = _endpoint;
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) external {
    // lzReceive must be called by the endpoint for security
    require(
      _msgSender() == address(lzEndpoint),
      "LzApp: invalid endpoint caller"
    );

    bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
    // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
    require(
      _srcAddress.length == trustedRemote.length &&
        keccak256(_srcAddress) == keccak256(trustedRemote),
      "LzApp: invalid source sending contract"
    );

    try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
      // do nothing
    } catch {
      // error / exception
      failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
      emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
    }
  }

  function nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) public {
    // only internal transaction
    require(
      _msgSender() == address(this),
      "NonblockingLzApp: caller must be LzApp"
    );
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  function _nonblockingLzReceive(
    uint16,
    bytes memory,
    uint64,
    bytes memory _payload
  ) internal {
    (address tokenRecipient, uint256 amount) = abi.decode(
      _payload,
      (address, uint256)
    );

    token.mint(tokenRecipient, amount);
  }
}
