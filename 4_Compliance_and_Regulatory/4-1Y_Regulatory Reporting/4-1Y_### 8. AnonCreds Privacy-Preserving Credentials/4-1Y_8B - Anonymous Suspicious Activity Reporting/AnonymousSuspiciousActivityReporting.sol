// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AnonymousSuspiciousActivityReporting is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    // Counter for report IDs
    Counters.Counter private _reportIdCounter;

    // Mapping to store anonymous reports
    mapping(uint256 => Report) private _reports;

    // Address of the regulatory authority
    address public regulatoryAuthority;

    // Events for reporting
    event AnonymousReportSubmitted(uint256 indexed reportId, bytes32 encryptedDataHash, uint256 timestamp);
    event AnonymousReportVerified(uint256 indexed reportId, address indexed verifier, bytes32 verifiedHash, uint256 timestamp);

    // Struct to store anonymous report data
    struct Report {
        bytes32 encryptedDataHash;
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

    // Function to submit an anonymous report
    function submitAnonymousReport(bytes32 encryptedDataHash) external whenNotPaused nonReentrant {
        require(encryptedDataHash != bytes32(0), "Invalid data hash");

        uint256 reportId = _reportIdCounter.current();
        _reports[reportId] = Report({
            encryptedDataHash: encryptedDataHash,
            isVerified: false,
            verifiedHash: bytes32(0)
        });

        emit AnonymousReportSubmitted(reportId, encryptedDataHash, block.timestamp);

        _reportIdCounter.increment();
    }

    // Function for the regulatory authority to verify a report
    function verifyAnonymousReport(uint256 reportId, bytes32 verifiedHash) external whenNotPaused nonReentrant {
        require(msg.sender == regulatoryAuthority, "Not authorized");
        require(verifiedHash != bytes32(0), "Invalid verified hash");

        Report storage report = _reports[reportId];
        require(report.encryptedDataHash != bytes32(0), "Report does not exist");

        report.isVerified = true;
        report.verifiedHash = verifiedHash;

        emit AnonymousReportVerified(reportId, msg.sender, verifiedHash, block.timestamp);
    }

    // Function to get the details of a report (only for regulatory authority)
    function getReportDetails(uint256 reportId) external view returns (bytes32, bool, bytes32) {
        require(msg.sender == regulatoryAuthority || msg.sender == owner(), "Not authorized");

        Report storage report = _reports[reportId];
        require(report.encryptedDataHash != bytes32(0), "Report does not exist");

        return (report.encryptedDataHash, report.isVerified, report.verifiedHash);
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
