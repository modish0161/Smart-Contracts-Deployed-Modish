// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AMLMonitoringAndReportingContract is ERC20, Ownable, Pausable, ReentrancyGuard, AccessControl {
    
    // Role for Compliance Officer
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Thresholds for suspicious activity monitoring
    uint256 public transactionThreshold;
    uint256 public dailyTransferLimit;

    // Mapping to track daily transfer amounts per user
    mapping(address => uint256) private _dailyTransfers;
    mapping(address => uint256) private _lastTransferDate;

    // Event for suspicious activity
    event SuspiciousActivityReported(address indexed user, uint256 amount, string reason);

    // Modifier to restrict actions to compliance officers only
    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_OFFICER_ROLE, msg.sender), "Caller is not a compliance officer");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _complianceOfficer,
        uint256 _transactionThreshold,
        uint256 _dailyTransferLimit
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, _complianceOfficer);
        transactionThreshold = _transactionThreshold;
        dailyTransferLimit = _dailyTransferLimit;
    }

    /**
     * @dev Overrides the ERC20 transfer function to include AML monitoring
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _monitorTransaction(msg.sender, amount);
        return super.transfer(recipient, amount);
    }

    /**
     * @dev Overrides the ERC20 transferFrom function to include AML monitoring
     * @param sender Address of the sender
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _monitorTransaction(sender, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Sets the transaction threshold for suspicious activity
     * @param _threshold New transaction threshold
     */
    function setTransactionThreshold(uint256 _threshold) external onlyOwner {
        transactionThreshold = _threshold;
    }

    /**
     * @dev Sets the daily transfer limit for suspicious activity
     * @param _limit New daily transfer limit
     */
    function setDailyTransferLimit(uint256 _limit) external onlyOwner {
        dailyTransferLimit = _limit;
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
     * @param amount Amount of the suspicious transaction
     * @param reason Reason for reporting the transaction
     */
    function reportSuspiciousActivity(address user, uint256 amount, string calldata reason) external onlyComplianceOfficer {
        emit SuspiciousActivityReported(user, amount, reason);
    }

    /**
     * @dev Internal function to monitor transactions
     * @param user Address of the user making the transaction
     * @param amount Amount of tokens transferred
     */
    function _monitorTransaction(address user, uint256 amount) internal {
        // Check for single transaction threshold
        if (amount >= transactionThreshold) {
            emit SuspiciousActivityReported(user, amount, "Transaction exceeds single transaction threshold");
        }

        // Check for daily transfer limit
        uint256 currentDay = block.timestamp / 1 days;
        if (_lastTransferDate[user] < currentDay) {
            _dailyTransfers[user] = 0;
            _lastTransferDate[user] = currentDay;
        }

        _dailyTransfers[user] += amount;

        if (_dailyTransfers[user] >= dailyTransferLimit) {
            emit SuspiciousActivityReported(user, _dailyTransfers[user], "Daily transfer limit exceeded");
        }
    }

    /**
     * @dev Internal function to include pause checks on token transfers
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
