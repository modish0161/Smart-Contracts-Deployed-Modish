// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract KYCAMLComplianceReporting is ERC20, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant REPORTING_ROLE = keccak256("REPORTING_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    struct ComplianceStatus {
        bool kycPassed;
        bool amlPassed;
    }

    mapping(address => ComplianceStatus) private _complianceStatus;
    address[] private _verifiedAddresses;

    event ComplianceReported(address indexed reporter, uint256 timestamp, uint256 totalVerified);
    event ComplianceStatusUpdated(address indexed user, bool kycPassed, bool amlPassed);
    event TransactionRestricted(address indexed user, string reason);

    modifier onlyCompliant(address user) {
        require(_complianceStatus[user].kycPassed, "User has not passed KYC check");
        require(_complianceStatus[user].amlPassed, "User has not passed AML check");
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REPORTING_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
    }

    /**
     * @notice Sets the compliance status for a user.
     * @param user The address of the user.
     * @param kycPassed Boolean indicating if the user has passed KYC.
     * @param amlPassed Boolean indicating if the user has passed AML.
     */
    function setComplianceStatus(address user, bool kycPassed, bool amlPassed) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _complianceStatus[user] = ComplianceStatus(kycPassed, amlPassed);

        if (kycPassed && amlPassed && !_isVerified(user)) {
            _verifiedAddresses.push(user);
        }

        emit ComplianceStatusUpdated(user, kycPassed, amlPassed);
    }

    /**
     * @notice Checks if an address is compliant.
     * @param user The address to check.
     * @return True if the user has passed both KYC and AML checks, false otherwise.
     */
    function isCompliant(address user) public view returns (bool) {
        return _complianceStatus[user].kycPassed && _complianceStatus[user].amlPassed;
    }

    /**
     * @notice Generates a compliance report for all verified users.
     * @return The list of all verified addresses.
     */
    function generateComplianceReport() external onlyRole(REPORTING_ROLE) nonReentrant returns (address[] memory) {
        emit ComplianceReported(msg.sender, block.timestamp, _verifiedAddresses.length);
        return _verifiedAddresses;
    }

    /**
     * @notice Checks if a user is already verified.
     * @param user The address to check.
     * @return True if the user is verified, false otherwise.
     */
    function _isVerified(address user) internal view returns (bool) {
        for (uint256 i = 0; i < _verifiedAddresses.length; i++) {
            if (_verifiedAddresses[i] == user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Override the transfer function to enforce compliance checks.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused onlyCompliant(from) onlyCompliant(to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @notice Pauses all token transfers. Can only be called by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers. Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Grants compliance officer role to a new address.
     * @param account The address to grant the role to.
     */
    function grantComplianceOfficerRole(address account) external onlyOwner {
        grantRole(COMPLIANCE_OFFICER_ROLE, account);
    }

    /**
     * @notice Revokes compliance officer role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeComplianceOfficerRole(address account) external onlyOwner {
        revokeRole(COMPLIANCE_OFFICER_ROLE, account);
    }

    /**
     * @notice Grants reporting role to a new address.
     * @param account The address to grant the role to.
     */
    function grantReportingRole(address account) external onlyOwner {
        grantRole(REPORTING_ROLE, account);
    }

    /**
     * @notice Revokes reporting role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeReportingRole(address account) external onlyOwner {
        revokeRole(REPORTING_ROLE, account);
    }
}
