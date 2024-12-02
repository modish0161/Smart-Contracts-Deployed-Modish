// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract AccreditedInvestorTaxReportingWithPrivacy is Ownable, AccessControl, ReentrancyGuard, Pausable, EIP712 {
    using ECDSA for bytes32;

    // Role for tax compliance officers
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Struct for storing encrypted tax reports
    struct TaxReport {
        bytes32 encryptedTaxAmount; // Encrypted tax amount using Zero-Knowledge (ZK) methods
        bytes32 proof;              // ZK proof for the tax amount
        address reporter;           // Address of the compliance officer
        uint256 timestamp;          // Time of tax reporting
    }

    // Mapping of investor address to their encrypted tax reports
    mapping(address => TaxReport[]) private taxReports;

    // Event for tracking tax reporting
    event TaxReported(address indexed investor, bytes32 encryptedTaxAmount, bytes32 proof, address indexed reporter, uint256 timestamp);

    // Domain separator for EIP712
    bytes32 private immutable _DOMAIN_SEPARATOR;

    // Constructor to set up the domain separator
    constructor() EIP712("AccreditedInvestorTaxReportingWithPrivacy", "1.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
        _DOMAIN_SEPARATOR = _domainSeparatorV4();
    }

    // Modifier to restrict function access to compliance officers
    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), "Caller is not a compliance officer");
        _;
    }

    // Function to report tax for an investor anonymously
    function reportTax(
        address investor,
        bytes32 encryptedTaxAmount,
        bytes32 proof
    ) external onlyComplianceOfficer nonReentrant whenNotPaused {
        require(investor != address(0), "Invalid investor address");
        require(encryptedTaxAmount != bytes32(0), "Invalid tax amount");
        require(proof != bytes32(0), "Invalid proof");

        // Store the tax report
        taxReports[investor].push(TaxReport({
            encryptedTaxAmount: encryptedTaxAmount,
            proof: proof,
            reporter: msg.sender,
            timestamp: block.timestamp
        }));

        emit TaxReported(investor, encryptedTaxAmount, proof, msg.sender, block.timestamp);
    }

    // Function to retrieve tax reports for an investor
    function getTaxReports(address investor) external view returns (TaxReport[] memory) {
        return taxReports[investor];
    }

    // Function to pause the contract (onlyOwner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (onlyOwner)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to add a compliance officer (onlyOwner)
    function addComplianceOfficer(address officer) external onlyOwner {
        grantRole(COMPLIANCE_ROLE, officer);
    }

    // Function to remove a compliance officer (onlyOwner)
    function removeComplianceOfficer(address officer) external onlyOwner {
        revokeRole(COMPLIANCE_ROLE, officer);
    }

    // Function to verify the encrypted tax amount using EIP-712 signature
    function verifyTaxAmount(
        address investor,
        bytes32 encryptedTaxAmount,
        bytes32 proof,
        bytes memory signature
    ) external view returns (bool) {
        bytes32 structHash = keccak256(abi.encode(
            keccak256("TaxReport(address investor,bytes32 encryptedTaxAmount,bytes32 proof)"),
            investor,
            encryptedTaxAmount,
            proof
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        return hasRole(COMPLIANCE_ROLE, signer);
    }

    // Function to get domain separator
    function domainSeparator() external view returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }
}
