// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TransactionMonitoringAndAMLContract is ERC777, Ownable, AccessControl, Pausable, ReentrancyGuard {

    // Role for AML Compliance Officers
    bytes32 public constant AML_COMPLIANCE_ROLE = keccak256("AML_COMPLIANCE_ROLE");

    // Thresholds for monitoring suspicious activities
    uint256 public largeTransactionThreshold;
    uint256 public frequentTransactionLimit;
    uint256 public timeWindow;

    // Mapping to track user's transaction count within the time window
    mapping(address => uint256) private _transactionCount;
    mapping(address => uint256) private _lastTransactionTimestamp;

    // Event for suspicious transaction pattern detected
    event SuspiciousActivityDetected(address indexed user, string activityType, uint256 amount);

    constructor(
        address[] memory defaultOperators,
        address amlOfficer,
        uint256 _largeTransactionThreshold,
        uint256 _frequentTransactionLimit,
        uint256 _timeWindow
    ) ERC777("MonitoringAMLToken", "MAT", defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(AML_COMPLIANCE_ROLE, amlOfficer);

        largeTransactionThreshold = _largeTransactionThreshold;
        frequentTransactionLimit = _frequentTransactionLimit;
        timeWindow = _timeWindow;
    }

    /**
     * @dev Sets the large transaction threshold for monitoring.
     * @param _threshold New large transaction threshold.
     */
    function setLargeTransactionThreshold(uint256 _threshold) external onlyRole(AML_COMPLIANCE_ROLE) {
        largeTransactionThreshold = _threshold;
    }

    /**
     * @dev Sets the limit for frequent transactions.
     * @param _limit New frequent transaction limit.
     */
    function setFrequentTransactionLimit(uint256 _limit) external onlyRole(AML_COMPLIANCE_ROLE) {
        frequentTransactionLimit = _limit;
    }

    /**
     * @dev Sets the time window for monitoring frequent transactions.
     * @param _window New time window in seconds.
     */
    function setTimeWindow(uint256 _window) external onlyRole(AML_COMPLIANCE_ROLE) {
        timeWindow = _window;
    }

    /**
     * @dev Overridden send function to include AML monitoring.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) public override whenNotPaused {
        _monitorTransaction(_msgSender(), amount);
        super.send(recipient, amount, data);
    }

    /**
     * @dev Overridden operatorSend function to include AML monitoring.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) public override whenNotPaused {
        _monitorTransaction(sender, amount);
        super.operatorSend(sender, recipient, amount, data, operatorData);
    }

    /**
     * @dev Monitors the transaction for suspicious activities.
     * @param user Address of the user making the transaction.
     * @param amount Amount of tokens transferred.
     */
    function _monitorTransaction(address user, uint256 amount) internal {
        // Check for large transaction
        if (amount >= largeTransactionThreshold) {
            emit SuspiciousActivityDetected(user, "Large Transaction", amount);
        }

        // Check for frequent transactions
        uint256 currentTime = block.timestamp;
        if (_lastTransactionTimestamp[user] + timeWindow < currentTime) {
            _transactionCount[user] = 0;
            _lastTransactionTimestamp[user] = currentTime;
        }

        _transactionCount[user] += 1;

        if (_transactionCount[user] > frequentTransactionLimit) {
            emit SuspiciousActivityDetected(user, "Frequent Transactions", amount);
        }
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
