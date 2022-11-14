// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { LibAccessControl } from "../libraries/LibAccessControl.sol";

contract AccessControlInitializer {
  function initialize(address admin) external {
    LibAccessControl._grantRole(LibAccessControl.DEFAULT_ADMIN_ROLE, admin);
  }
}
