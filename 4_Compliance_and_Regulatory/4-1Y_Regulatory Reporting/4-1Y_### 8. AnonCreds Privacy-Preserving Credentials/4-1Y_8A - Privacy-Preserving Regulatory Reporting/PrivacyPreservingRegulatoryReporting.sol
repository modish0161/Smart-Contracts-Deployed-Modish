// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PrivacyPreservingRegulatoryReporting is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    // Counter for report IDs
    Counters.Counter private _reportIdCounter;

    // Mapping to store report data securely
    mapping(uint256 => Report) private _reports;

    // Address of the regulatory authority
    address public regulatoryAuthority;

    // Events for reporting
    event ReportSubmitted(uint256 indexed reportId, address indexed submitter, bytes32 reportHash, uint256 timestamp);
    event ReportVerified(uint256 indexed reportId, address indexed verifier, bytes32 verifiedHash, uint256 timestamp);

    // Struct to store report data
    struct Report {
        address submitter;
        bytes32 reportHash;
        bool isVerified;
        bytes32 verifiedHash;
    }

    constructor(address _regulatoryAuthority) {
        require(_regulatoryAuthority != address(0), "Invalid authority address");
        regulatoryAuthority = _regulatoryAuthority;
    }

    // Function to set the regulatory authority
    function setRegulatoryAuthority(address _authority) external onlyOwner {
        require(_authority != address(0), "Invalid authority address");
        regulatoryAuthority = _authority;
    }

    // Function to submit a privacy-preserving report
    function submitReport(bytes32 reportHash) external whenNotPaused nonReentrant {
        require(reportHash != bytes32(0), "Invalid report hash");

        uint256 reportId = _reportIdCounter.current();
        _reports[reportId] = Report({
            submitter: msg.sender,
            reportHash: reportHash,
            isVerified: false,
            verifiedHash: bytes32(0)
        });

        emit ReportSubmitted(reportId, msg.sender, reportHash, block.timestamp);

        _reportIdCounter.increment();
    }

    // Function for the regulatory authority to verify a report
    function verifyReport(uint256 reportId, bytes32 verifiedHash) external whenNotPaused nonReentrant {
        require(msg.sender == regulatoryAuthority, "Not authorized");
        require(verifiedHash != bytes32(0), "Invalid verified hash");

        Report storage report = _reports[reportId];
        require(report.submitter != address(0), "Report does not exist");

        report.isVerified = true;
        report.verifiedHash = verifiedHash;

        emit ReportVerified(reportId, msg.sender, verifiedHash, block.timestamp);
    }

    // Function to get the details of a report (only for regulatory authority)
    function getReport(uint256 reportId) external view returns (address, bytes32, bool, bytes32) {
        require(msg.sender == regulatoryAuthority || msg.sender == owner(), "Not authorized");

        Report storage report = _reports[reportId];
        require(report.submitter != address(0), "Report does not exist");

        return (report.submitter, report.reportHash, report.isVerified, report.verifiedHash);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
