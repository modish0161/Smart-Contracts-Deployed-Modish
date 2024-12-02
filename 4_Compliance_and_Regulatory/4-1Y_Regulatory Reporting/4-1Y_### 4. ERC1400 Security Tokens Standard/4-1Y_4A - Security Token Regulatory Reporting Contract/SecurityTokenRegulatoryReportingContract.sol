// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract SecurityTokenRegulatoryReportingContract is IERC1400, ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Role Definitions
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Structs for storing report data
    struct TransactionReport {
        uint256 id;
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
    }

    struct CorporateActionReport {
        uint256 id;
        string actionType; // e.g., "Dividend", "Stock Split"
        uint256 amount;
        uint256 timestamp;
    }

    // Event Definitions
    event TransactionReported(uint256 indexed id, address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event CorporateActionReported(uint256 indexed id, string actionType, uint256 amount, uint256 timestamp);

    // Internal Counters
    Counters.Counter private _transactionReportIdCounter;
    Counters.Counter private _corporateActionReportIdCounter;

    // Reports Storage
    TransactionReport[] public transactionReports;
    CorporateActionReport[] public corporateActionReports;

    // Compliance
    EnumerableSet.AddressSet private compliantUsers;
    mapping(address => bool) public isVerified;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // Modifiers
    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_OFFICER_ROLE, msg.sender), "Caller is not a compliance officer");
        _;
    }

    modifier onlyRegulator() {
        require(hasRole(REGULATOR_ROLE, msg.sender), "Caller is not a regulator");
        _;
    }

    // Compliance Management
    function updateVerificationStatus(address user, bool status) external onlyComplianceOfficer {
        isVerified[user] = status;
        if (status) {
            compliantUsers.add(user);
        } else {
            compliantUsers.remove(user);
        }
    }

    function isUserCompliant(address user) external view returns (bool) {
        return compliantUsers.contains(user);
    }

    // Token Transfer with Compliance Checks
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        require(isVerified[_msgSender()], "Sender not verified");
        require(isVerified[to], "Recipient not verified");
        super.transfer(to, amount);
        _reportTransaction(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        require(isVerified[from], "Sender not verified");
        require(isVerified[to], "Recipient not verified");
        super.transferFrom(from, to, amount);
        _reportTransaction(from, to, amount);
        return true;
    }

    // Reporting Functions
    function _reportTransaction(address from, address to, uint256 amount) internal {
        uint256 newReportId = _transactionReportIdCounter.current();
        transactionReports.push(TransactionReport({
            id: newReportId,
            from: from,
            to: to,
            amount: amount,
            timestamp: block.timestamp
        }));
        emit TransactionReported(newReportId, from, to, amount, block.timestamp);
        _transactionReportIdCounter.increment();
    }

    function reportCorporateAction(string memory actionType, uint256 amount) external onlyComplianceOfficer {
        uint256 newReportId = _corporateActionReportIdCounter.current();
        corporateActionReports.push(CorporateActionReport({
            id: newReportId,
            actionType: actionType,
            amount: amount,
            timestamp: block.timestamp
        }));
        emit CorporateActionReported(newReportId, actionType, amount, block.timestamp);
        _corporateActionReportIdCounter.increment();
    }

    // Pause and Unpause Contract
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Getters for Reporting Data
    function getTransactionReports() external view returns (TransactionReport[] memory) {
        return transactionReports;
    }

    function getCorporateActionReports() external view returns (CorporateActionReport[] memory) {
        return corporateActionReports;
    }
}
