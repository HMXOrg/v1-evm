// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { LibAccessControl } from "../libraries/LibAccessControl.sol";
import { AccessControlFacetInterface } from "../interfaces/AccessControlFacetInterface.sol";

contract AccessControlFacet is AccessControlFacetInterface {
  // -------------
  //    Errors
  // -------------
  error LibAccessControl_CanOnlyRenounceSelf();

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view returns (bool) {
    return LibAccessControl._hasRole(role, account);
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view returns (bytes32) {
    return LibAccessControl._getRoleAdmin(role);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleGranted} event.
   */
  function grantRole(bytes32 role, address account) public {
    LibAccessControl._checkRole(getRoleAdmin(role));
    LibAccessControl._grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleRevoked} event.
   */
  function revokeRole(bytes32 role, address account) public {
    LibAccessControl._checkRole(getRoleAdmin(role));
    LibAccessControl._revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been revoked `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   *
   * May emit a {RoleRevoked} event.
   */
  function renounceRole(bytes32 role, address account) public {
    if (account != msg.sender) {
      revert LibAccessControl_CanOnlyRenounceSelf();
    }

    LibAccessControl._revokeRole(role, account);
  }
}
