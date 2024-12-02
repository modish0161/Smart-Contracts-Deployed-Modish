// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AnonymousAMLReporting is Ownable, Pausable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    struct Report {
        address reporter;
        string details; // Contains encrypted or hashed details of suspicious activity
        uint256 timestamp;
    }

    Counters.Counter private reportIds;
    mapping(uint256 => Report) private reports; // Stores reports based on reportId
    address public amlComplianceOfficer;
    uint256 public reportCount;
    mapping(address => bool) private authorizedReporters;

    event SuspiciousActivityReported(uint256 reportId, address indexed reporter, uint256 timestamp);
    event AMLComplianceOfficerUpdated(address indexed newOfficer);
    event AuthorizedReporterAdded(address indexed reporter);
    event AuthorizedReporterRemoved(address indexed reporter);

    modifier onlyComplianceOfficer() {
        require(msg.sender == amlComplianceOfficer, "Only the AML compliance officer can perform this action");
        _;
    }

    constructor(address _amlComplianceOfficer) {
        require(_amlComplianceOfficer != address(0), "Invalid compliance officer address");
        amlComplianceOfficer = _amlComplianceOfficer;
    }

    /**
     * @notice Report suspicious activity anonymously.
     * @param _details Encrypted or hashed details of the suspicious activity.
     */
    function reportSuspiciousActivity(string memory _details) external whenNotPaused {
        require(authorizedReporters[msg.sender], "Unauthorized reporter");

        reportIds.increment();
        uint256 newReportId = reportIds.current();
        
        reports[newReportId] = Report({
            reporter: msg.sender,
            details: _details,
            timestamp: block.timestamp
        });

        reportCount += 1;

        emit SuspiciousActivityReported(newReportId, msg.sender, block.timestamp);
    }

    /**
     * @notice View the details of a reported suspicious activity.
     * @param reportId ID of the report to view.
     * @return Reporter address, details of the report, and timestamp.
     */
    function viewReport(uint256 reportId) external view onlyComplianceOfficer returns (address, string memory, uint256) {
        require(reportId > 0 && reportId <= reportIds.current(), "Invalid report ID");
        Report memory report = reports[reportId];
        return (report.reporter, report.details, report.timestamp);
    }

    /**
     * @notice Add an authorized reporter.
     * @param reporter Address to be added as authorized reporter.
     */
    function addAuthorizedReporter(address reporter) external onlyOwner {
        require(reporter != address(0), "Invalid address");
        authorizedReporters[reporter] = true;
        emit AuthorizedReporterAdded(reporter);
    }

    /**
     * @notice Remove an authorized reporter.
     * @param reporter Address to be removed as authorized reporter.
     */
    function removeAuthorizedReporter(address reporter) external onlyOwner {
        require(reporter != address(0), "Invalid address");
        authorizedReporters[reporter] = false;
        emit AuthorizedReporterRemoved(reporter);
    }

    /**
     * @notice Set a new AML compliance officer.
     * @param _newOfficer Address of the new compliance officer.
     */
    function setAMLComplianceOfficer(address _newOfficer) external onlyOwner {
        require(_newOfficer != address(0), "Invalid address");
        amlComplianceOfficer = _newOfficer;
        emit AMLComplianceOfficerUpdated(_newOfficer);
    }

    /**
     * @notice Pauses the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
