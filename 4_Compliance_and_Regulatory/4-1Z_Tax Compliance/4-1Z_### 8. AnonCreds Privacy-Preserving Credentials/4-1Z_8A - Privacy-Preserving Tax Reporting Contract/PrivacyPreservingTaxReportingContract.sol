// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PrivacyPreservingTaxReportingContract is Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for tax compliance officers to manage tax settings and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Struct for storing tax report details
    struct TaxReport {
        uint256 encryptedAmount; // Encrypted tax amount
        bytes32 proof;           // Zero-knowledge proof for verification
        address reporter;        // Address of the compliance officer
        uint256 timestamp;       // Time of the report
    }

    // Mapping to store tax reports by transaction ID
    mapping(bytes32 => TaxReport[]) public taxReports;

    // Address of the tax authority for remittance
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxReported(bytes32 indexed txId, uint256 encryptedAmount, bytes32 proof, address indexed reporter, uint256 timestamp);
    event TaxAuthorityUpdated(address oldTaxAuthority, address newTaxAuthority);

    constructor(address initialTaxAuthority) {
        require(initialTaxAuthority != address(0), "Invalid tax authority address");
        taxAuthority = initialTaxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Modifier to restrict function access to compliance officers
    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), "Caller is not a compliance officer");
        _;
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Function to report tax using zero-knowledge proof (only by compliance officers)
    function reportTax(
        bytes32 txId,
        uint256 encryptedAmount,
        bytes32 proof
    ) external onlyComplianceOfficer nonReentrant {
        require(encryptedAmount > 0, "Invalid tax amount");
        require(proof != bytes32(0), "Invalid proof");

        // Store the tax report
        taxReports[txId].push(TaxReport({
            encryptedAmount: encryptedAmount,
            proof: proof,
            reporter: msg.sender,
            timestamp: block.timestamp
        }));

        emit TaxReported(txId, encryptedAmount, proof, msg.sender, block.timestamp);
    }

    // Function to get the list of tax reports for a given transaction ID
    function getTaxReports(bytes32 txId) external view returns (TaxReport[] memory) {
        return taxReports[txId];
    }

    // Function to pause the contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to add a compliance officer (only owner)
    function addComplianceOfficer(address officer) external onlyOwner {
        grantRole(COMPLIANCE_ROLE, officer);
    }

    // Function to remove a compliance officer (only owner)
    function removeComplianceOfficer(address officer) external onlyOwner {
        revokeRole(COMPLIANCE_ROLE, officer);
    }
}
