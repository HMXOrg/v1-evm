// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./MintableToken.sol";

contract EsP88 is MintableToken {
  constructor() ERC20("esP88", "esP88") {}
}
