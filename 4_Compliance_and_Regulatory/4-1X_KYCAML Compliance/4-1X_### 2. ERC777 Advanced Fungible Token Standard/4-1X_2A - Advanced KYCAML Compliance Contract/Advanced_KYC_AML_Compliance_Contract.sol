// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AdvancedKYCAMLComplianceContract is ERC777, Ownable, AccessControl, Pausable, ReentrancyGuard {

    // Role for Compliance Officers
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Mapping to store the KYC approval status
    mapping(address => bool) private _kycApproved;

    // Mapping to store blacklisted addresses
    mapping(address => bool) private _blacklisted;

    // Event to report suspicious activities
    event SuspiciousActivityReported(address indexed user, string reason);

    // Modifier to ensure only KYC-approved users can transfer tokens
    modifier onlyKYCApproved(address user) {
        require(_kycApproved[user], "User is not KYC approved");
        _;
    }

    // Modifier to ensure a user is not blacklisted
    modifier notBlacklisted(address user) {
        require(!_blacklisted[user], "User is blacklisted");
        _;
    }

    constructor(
        address[] memory defaultOperators,
        address complianceOfficer
    ) ERC777("AdvancedKYCAMLToken", "AKAT", defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, complianceOfficer);
    }

    /**
     * @dev Approves KYC for a user
     * @param user Address to approve KYC
     */
    function approveKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = true;
    }

    /**
     * @dev Revokes KYC for a user
     * @param user Address to revoke KYC
     */
    function revokeKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = false;
    }

    /**
     * @dev Blacklists a user
     * @param user Address to blacklist
     */
    function blacklist(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _blacklisted[user] = true;
        emit SuspiciousActivityReported(user, "User blacklisted");
    }

    /**
     * @dev Removes a user from the blacklist
     * @param user Address to remove from blacklist
     */
    function removeBlacklist(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _blacklisted[user] = false;
    }

    /**
     * @dev Checks if a user is KYC approved
     * @param user Address to check
     * @return true if the user is KYC approved, false otherwise
     */
    function isKYCApproved(address user) external view returns (bool) {
        return _kycApproved[user];
    }

    /**
     * @dev Checks if a user is blacklisted
     * @param user Address to check
     * @return true if the user is blacklisted, false otherwise
     */
    function isBlacklisted(address user) external view returns (bool) {
        return _blacklisted[user];
    }

    /**
     * @dev Overridden transfer function to include KYC and blacklist checks
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override onlyKYCApproved(from) notBlacklisted(from) notBlacklisted(to) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    /**
     * @dev Function to pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Function to unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Function to report suspicious activity manually
     * @param user Address of the user
     * @param reason Reason for reporting
     */
    function reportSuspiciousActivity(address user, string memory reason) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        emit SuspiciousActivityReported(user, reason);
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfers
     */
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
