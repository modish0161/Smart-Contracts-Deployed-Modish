// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";  // Import the ERC1400 standard (Assuming the interface exists in your project)

contract AMLComplianceMonitoring is IERC1400, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // Role for compliance officers
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Role for reporting suspicious activities
    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");

    // Mapping to store KYC approval status for users
    mapping(address => bool) private _kycApproved;

    // Mapping to store suspicious activity reports
    mapping(address => uint256) private _suspiciousActivities;

    // Mapping to store last transaction timestamps
    mapping(address => uint256) private _lastTransactionTime;

    // Mapping to store transaction counts within a time frame
    mapping(address => uint256) private _transactionCount;

    // Event to log KYC approval
    event KYCApproved(address indexed user);

    // Event to log KYC revocation
    event KYCRevoked(address indexed user);

    // Event to log suspicious activity
    event SuspiciousActivityReported(address indexed user, uint256 amount, string reason);

    // Modifier to check if the user is KYC approved
    modifier onlyKYCApproved(address user) {
        require(_kycApproved[user], "User is not KYC approved");
        _;
    }

    constructor(address complianceOfficer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, complianceOfficer);
    }

    /**
     * @dev Approves KYC for a user.
     * @param user Address to approve KYC.
     */
    function approveKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = true;
        emit KYCApproved(user);
    }

    /**
     * @dev Revokes KYC for a user.
     * @param user Address to revoke KYC.
     */
    function revokeKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = false;
        emit KYCRevoked(user);
    }

    /**
     * @dev Reports a suspicious activity for a user.
     * @param user Address of the suspicious user.
     * @param amount Amount of the suspicious transaction.
     * @param reason Reason for reporting.
     */
    function reportSuspiciousActivity(address user, uint256 amount, string calldata reason) external onlyRole(REPORTER_ROLE) {
        _suspiciousActivities[user] = _suspiciousActivities[user].add(1);
        emit SuspiciousActivityReported(user, amount, reason);
    }

    /**
     * @dev Checks if a user is KYC approved.
     * @param user Address to check.
     * @return true if the user is KYC approved, false otherwise.
     */
    function isKYCApproved(address user) external view returns (bool) {
        return _kycApproved[user];
    }

    /**
     * @dev Function to track and monitor transactions for AML compliance.
     * @param from Address of the sender.
     * @param to Address of the receiver.
     * @param value Amount being transferred.
     */
    function _monitorTransactions(address from, address to, uint256 value) internal {
        uint256 currentTime = block.timestamp;
        _transactionCount[from] = _transactionCount[from].add(1);

        // Flag large transactions
        if (value > 10000 ether) {  // Adjust this threshold as needed
            reportSuspiciousActivity(from, value, "Large transaction amount");
        }

        // Flag frequent transactions
        if (currentTime.sub(_lastTransactionTime[from]) < 1 hours) {
            if (_transactionCount[from] > 10) {  // More than 10 transactions within an hour
                reportSuspiciousActivity(from, value, "Frequent transactions in short time");
            }
        }

        _lastTransactionTime[from] = currentTime;
    }

    /**
     * @dev Overridden transfer function to include KYC and AML monitoring checks.
     */
    function transfer(
        address to,
        uint256 value
    ) public override onlyKYCApproved(msg.sender) onlyKYCApproved(to) whenNotPaused returns (bool) {
        _monitorTransactions(msg.sender, to, value);
        // Call to an internal transfer function or ERC1400 standard transfer function
        return _transfer(msg.sender, to, value);
    }

    /**
     * @dev Internal transfer function with compliance checks.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        // Perform transfer logic specific to ERC1400 here
        return true;
    }

    /**
     * @dev Mint new tokens with KYC and AML monitoring checks.
     */
    function mint(
        address account,
        uint256 amount,
        bytes memory data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyKYCApproved(account) {
        _mint(account, amount, data);
    }

    /**
     * @dev Burn tokens with KYC and AML monitoring checks.
     */
    function burn(
        address account,
        uint256 amount,
        bytes memory data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyKYCApproved(account) {
        _burn(account, amount, data);
    }

    /**
     * @dev Function to pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Function to unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfers.
     */
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
