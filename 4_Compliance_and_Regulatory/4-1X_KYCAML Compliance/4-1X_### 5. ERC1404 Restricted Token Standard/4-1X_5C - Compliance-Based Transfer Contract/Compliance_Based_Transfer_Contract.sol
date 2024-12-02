// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol"; // Assuming ERC1404 interface is available

contract ComplianceBasedTransferContract is IERC1404, Ownable, AccessControl, Pausable {
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Mapping for KYC-approved users
    mapping(address => bool) private _kycApproved;

    // Mapping for restricted users (e.g., users who failed KYC/AML checks)
    mapping(address => bool) private _restricted;

    // Mapping for transfer restrictions (0 - No restriction, 1 - Not KYC/AML compliant, 2 - Restricted by compliance officer)
    mapping(address => uint8) private _restrictions;

    // Event for KYC approval
    event KYCApproved(address indexed user);

    // Event for KYC revocation
    event KYCRevoked(address indexed user);

    // Event for compliance restriction applied
    event ComplianceRestrictionApplied(address indexed user, string reason);

    // Event for compliance restriction removed
    event ComplianceRestrictionRemoved(address indexed user);

    constructor(address complianceOfficer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, complianceOfficer);
    }

    /**
     * @dev Approve KYC for a user.
     * @param user Address of the user to approve.
     */
    function approveKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = true;
        _updateRestriction(user);
        emit KYCApproved(user);
    }

    /**
     * @dev Revoke KYC for a user.
     * @param user Address of the user to revoke.
     */
    function revokeKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = false;
        _updateRestriction(user);
        emit KYCRevoked(user);
    }

    /**
     * @dev Apply compliance restriction to a user.
     * @param user Address of the user to restrict.
     * @param reason Reason for restriction.
     */
    function applyComplianceRestriction(address user, string calldata reason) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[user] = true;
        _updateRestriction(user);
        emit ComplianceRestrictionApplied(user, reason);
    }

    /**
     * @dev Remove compliance restriction from a user.
     * @param user Address of the user to remove restriction.
     */
    function removeComplianceRestriction(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[user] = false;
        _updateRestriction(user);
        emit ComplianceRestrictionRemoved(user);
    }

    /**
     * @dev Internal function to update transfer restriction based on compliance status.
     * @param user Address of the user to update restriction for.
     */
    function _updateRestriction(address user) internal {
        if (!_kycApproved[user]) {
            _restrictions[user] = 1; // Not KYC compliant
        } else if (_restricted[user]) {
            _restrictions[user] = 2; // Restricted by compliance officer
        } else {
            _restrictions[user] = 0; // No restrictions
        }
    }

    /**
     * @dev Check if a user is KYC-approved.
     * @param user Address to check.
     * @return true if the user is KYC-approved, false otherwise.
     */
    function isKYCApproved(address user) public view returns (bool) {
        return _kycApproved[user];
    }

    /**
     * @dev Check if a user is restricted by compliance.
     * @param user Address to check.
     * @return true if the user is restricted, false otherwise.
     */
    function isRestricted(address user) public view returns (bool) {
        return _restricted[user];
    }

    /**
     * @dev Check the restriction code for a user.
     * @param user Address to check.
     * @return The restriction code (0 - No restriction, 1 - Not KYC compliant, 2 - Compliance restricted).
     */
    function detectTransferRestriction(address user) public view override returns (uint8) {
        return _restrictions[user];
    }

    /**
     * @dev Returns the reason for the transfer restriction.
     * @param restrictionCode The restriction code to check.
     * @return A string indicating the reason for the restriction.
     */
    function messageForTransferRestriction(uint8 restrictionCode) public pure override returns (string memory) {
        if (restrictionCode == 0) {
            return "No restrictions";
        } else if (restrictionCode == 1) {
            return "User is not KYC compliant";
        } else if (restrictionCode == 2) {
            return "User is restricted by compliance";
        } else {
            return "Unknown restriction";
        }
    }

    /**
     * @dev Modifier to check if the user is compliant for transfers.
     */
    modifier onlyCompliant(address user) {
        require(_restrictions[user] == 0, messageForTransferRestriction(_restrictions[user]));
        _;
    }

    /**
     * @dev Fallback function to reject Ether transfers.
     */
    receive() external payable {
        revert("Contract does not accept Ether");
    }

    /**
     * @dev Pauses all token transfers in case of a security issue.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
