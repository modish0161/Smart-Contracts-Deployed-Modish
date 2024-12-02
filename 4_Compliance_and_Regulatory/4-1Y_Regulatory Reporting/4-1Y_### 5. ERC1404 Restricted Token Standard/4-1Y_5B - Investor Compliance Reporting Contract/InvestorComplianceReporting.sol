// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC1404.sol"; // Interface for ERC1404 standard

contract InvestorComplianceReporting is IERC1404, ERC20Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Counters for compliance report IDs and restrictions
    Counters.Counter private _complianceReportIdCounter;
    Counters.Counter private _restrictionIdCounter;

    // Structure for storing compliance reports
    struct ComplianceReport {
        uint256 reportId;
        address investor;
        string status;
        string dataHash; // Hash of the compliance data for integrity
        uint256 timestamp;
    }

    // Structure for tracking restrictions
    struct Restriction {
        uint256 restrictionId;
        string description;
    }

    // Mapping for storing compliance reports
    mapping(uint256 => ComplianceReport) public complianceReports;

    // Mapping for storing restriction descriptions
    mapping(uint256 => Restriction) public restrictions;

    // Set of compliant addresses
    EnumerableSet.AddressSet private compliantAddresses;

    // Mapping to track restriction status of addresses
    mapping(address => uint256) public addressRestrictions;

    // Event for compliance reports
    event ComplianceReportSubmitted(
        uint256 indexed reportId,
        address indexed investor,
        string status,
        string dataHash,
        uint256 timestamp
    );

    // Event for restriction updates
    event RestrictionUpdated(
        uint256 indexed restrictionId,
        address indexed account,
        string restriction,
        uint256 timestamp
    );

    // Constructor to initialize the contract
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Modifier to check if the address is compliant
    modifier onlyCompliant() {
        require(isCompliant(msg.sender), "InvestorComplianceReporting: Address not compliant");
        _;
    }

    // Function to check compliance of an address
    function isCompliant(address account) public view returns (bool) {
        return compliantAddresses.contains(account);
    }

    // Function to add compliant addresses
    function addCompliantAddress(address account) external onlyOwner {
        require(!compliantAddresses.contains(account), "InvestorComplianceReporting: Address already compliant");
        compliantAddresses.add(account);
    }

    // Function to remove compliant addresses
    function removeCompliantAddress(address account) external onlyOwner {
        require(compliantAddresses.contains(account), "InvestorComplianceReporting: Address not compliant");
        compliantAddresses.remove(account);
    }

    // Function to submit a compliance report
    function submitComplianceReport(address investor, string memory status, string memory dataHash) external onlyOwner whenNotPaused {
        require(isCompliant(investor), "InvestorComplianceReporting: Investor not compliant");

        uint256 newReportId = _complianceReportIdCounter.current();

        ComplianceReport memory newReport = ComplianceReport({
            reportId: newReportId,
            investor: investor,
            status: status,
            dataHash: dataHash,
            timestamp: block.timestamp
        });

        complianceReports[newReportId] = newReport;
        emit ComplianceReportSubmitted(newReportId, investor, status, dataHash, block.timestamp);

        _complianceReportIdCounter.increment();
    }

    // Function to transfer tokens with compliance checks
    function transfer(address to, uint256 value) public override onlyCompliant returns (bool) {
        require(_checkRestriction(msg.sender, to), "InvestorComplianceReporting: Transfer restricted");

        bool success = super.transfer(to, value);
        if (success) {
            _reportTransferCompliance(msg.sender, to, value);
        }
        return success;
    }

    // Function to transfer tokens from an address with compliance checks
    function transferFrom(address from, address to, uint256 value) public override onlyCompliant returns (bool) {
        require(_checkRestriction(from, to), "InvestorComplianceReporting: Transfer restricted");

        bool success = super.transferFrom(from, to, value);
        if (success) {
            _reportTransferCompliance(from, to, value);
        }
        return success;
    }

    // Internal function to check restrictions before transfers
    function _checkRestriction(address from, address to) internal view returns (bool) {
        return addressRestrictions[from] == 0 && addressRestrictions[to] == 0;
    }

    // Internal function to report transfer compliance data
    function _reportTransferCompliance(address from, address to, uint256 value) internal {
        // Logic for reporting transfer compliance data, can be extended for additional logic
    }

    // Function to add or update a restriction on an address
    function addOrUpdateRestriction(address account, string memory restriction) external onlyOwner {
        uint256 restrictionId = addressRestrictions[account];
        if (restrictionId == 0) {
            _restrictionIdCounter.increment();
            restrictionId = _restrictionIdCounter.current();
            addressRestrictions[account] = restrictionId;
        }

        restrictions[restrictionId] = Restriction({
            restrictionId: restrictionId,
            description: restriction
        });

        emit RestrictionUpdated(restrictionId, account, restriction, block.timestamp);
    }

    // Function to remove a restriction from an address
    function removeRestriction(address account) external onlyOwner {
        uint256 restrictionId = addressRestrictions[account];
        require(restrictionId != 0, "InvestorComplianceReporting: No restriction to remove");

        delete restrictions[restrictionId];
        delete addressRestrictions[account];

        emit RestrictionUpdated(restrictionId, account, "No Restriction", block.timestamp);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to get the total number of compliance reports
    function getTotalComplianceReports() external view returns (uint256) {
        return _complianceReportIdCounter.current();
    }

    // Function to get a compliance report by ID
    function getComplianceReportById(uint256 reportId) external view returns (ComplianceReport memory) {
        return complianceReports[reportId];
    }

    // Function to get the total number of restrictions
    function getTotalRestrictions() external view returns (uint256) {
        return _restrictionIdCounter.current();
    }

    // Function to get a restriction by ID
    function getRestrictionById(uint256 restrictionId) external view returns (Restriction memory) {
        return restrictions[restrictionId];
    }
}