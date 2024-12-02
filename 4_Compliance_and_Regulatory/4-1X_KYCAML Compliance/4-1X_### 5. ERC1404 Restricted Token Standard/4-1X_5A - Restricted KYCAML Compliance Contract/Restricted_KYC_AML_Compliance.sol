// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";  // Assuming ERC1404 standard is imported

contract RestrictedKYCAMLCompliance is ERC1404, Ownable, AccessControl, Pausable {
    using SafeMath for uint256;

    // Role for compliance officers
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Mapping for storing KYC-approved users
    mapping(address => bool) private _kycApproved;

    // Mapping for storing restrictions (e.g., restricted users or restricted transfers)
    mapping(address => bool) private _restricted;

    // Event for KYC approval
    event KYCApproved(address indexed user);

    // Event for KYC revocation
    event KYCRevoked(address indexed user);

    // Event for restriction applied
    event RestrictionApplied(address indexed user, string reason);

    // Event for restriction removed
    event RestrictionRemoved(address indexed user);

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
        emit KYCApproved(user);
    }

    /**
     * @dev Revoke KYC for a user.
     * @param user Address of the user to revoke.
     */
    function revokeKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = false;
        emit KYCRevoked(user);
    }

    /**
     * @dev Apply restriction to a user for AML or KYC violations.
     * @param user Address of the user to restrict.
     * @param reason Reason for restriction.
     */
    function applyRestriction(address user, string memory reason) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[user] = true;
        emit RestrictionApplied(user, reason);
    }

    /**
     * @dev Remove restriction from a user after resolution.
     * @param user Address of the user to unrestrict.
     */
    function removeRestriction(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[user] = false;
        emit RestrictionRemoved(user);
    }

    /**
     * @dev Check if a user is KYC approved.
     * @param user Address to check.
     * @return true if the user is KYC approved, false otherwise.
     */
    function isKYCApproved(address user) public view returns (bool) {
        return _kycApproved[user];
    }

    /**
     * @dev Check if a user is restricted.
     * @param user Address to check.
     * @return true if the user is restricted, false otherwise.
     */
    function isRestricted(address user) public view returns (bool) {
        return _restricted[user];
    }

    /**
     * @dev Override to add KYC and restriction checks to the transfer function.
     * Only allow transfers between KYC-approved and unrestricted users.
     * @param to The recipient of the transfer.
     * @param amount The amount to transfer.
     */
    function transfer(address to, uint256 amount) public override onlyKYCApprovedAndUnrestricted(msg.sender) onlyKYCApprovedAndUnrestricted(to) whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    /**
     * @dev Modifier to check if the user is KYC-approved and unrestricted.
     */
    modifier onlyKYCApprovedAndUnrestricted(address user) {
        require(_kycApproved[user], "User is not KYC approved");
        require(!_restricted[user], "User is restricted");
        _;
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

    /**
     * @dev Fallback function to reject Ether transfers.
     */
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
