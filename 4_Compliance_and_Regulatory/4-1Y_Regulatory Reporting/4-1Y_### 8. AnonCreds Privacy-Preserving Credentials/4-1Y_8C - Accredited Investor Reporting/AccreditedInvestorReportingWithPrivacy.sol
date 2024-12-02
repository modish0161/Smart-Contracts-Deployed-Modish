// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AccreditedInvestorReportingWithPrivacy is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Regulatory Authority Address
    address public regulatoryAuthority;

    // Accredited Investor Data
    struct Accreditation {
        bytes32 encryptedDataHash; // Encrypted hash of investor accreditation status
        uint256 expirationDate; // Expiration date of accreditation status
    }

    // Mapping of investor addresses to their accreditation data
    mapping(address => Accreditation) private _accreditations;

    // List of accredited investors
    EnumerableSet.AddressSet private _accreditedInvestors;

    // Events for reporting
    event InvestorAccredited(address indexed investor, bytes32 encryptedDataHash, uint256 expirationDate, uint256 timestamp);
    event InvestorRemoved(address indexed investor, uint256 timestamp);
    event AccreditationReportSubmitted(bytes32 indexed reportHash, uint256 timestamp);

    constructor(address _regulatoryAuthority) {
        require(_regulatoryAuthority != address(0), "Invalid authority address");
        regulatoryAuthority = _regulatoryAuthority;
    }

    // Modifier to restrict access to the regulatory authority
    modifier onlyRegulatoryAuthority() {
        require(msg.sender == regulatoryAuthority, "Not authorized");
        _;
    }

    // Function to set the regulatory authority
    function setRegulatoryAuthority(address _authority) external onlyOwner {
        require(_authority != address(0), "Invalid authority address");
        regulatoryAuthority = _authority;
    }

    // Function to add an accredited investor
    function addAccreditedInvestor(address investor, bytes32 encryptedDataHash, uint256 expirationDate) external onlyOwner whenNotPaused {
        require(investor != address(0), "Invalid investor address");
        require(encryptedDataHash != bytes32(0), "Invalid data hash");
        require(expirationDate > block.timestamp, "Expiration date must be in the future");

        _accreditations[investor] = Accreditation({
            encryptedDataHash: encryptedDataHash,
            expirationDate: expirationDate
        });
        _accreditedInvestors.add(investor);

        emit InvestorAccredited(investor, encryptedDataHash, expirationDate, block.timestamp);
    }

    // Function to remove an accredited investor
    function removeAccreditedInvestor(address investor) external onlyOwner whenNotPaused {
        require(investor != address(0), "Invalid investor address");
        require(_accreditedInvestors.contains(investor), "Investor not found");

        _accreditedInvestors.remove(investor);
        delete _accreditations[investor];

        emit InvestorRemoved(investor, block.timestamp);
    }

    // Function for the regulatory authority to submit an accreditation report
    function submitAccreditationReport(bytes32 reportHash) external onlyRegulatoryAuthority whenNotPaused {
        require(reportHash != bytes32(0), "Invalid report hash");

        emit AccreditationReportSubmitted(reportHash, block.timestamp);
    }

    // Function to get encrypted accreditation data (only for regulatory authority)
    function getEncryptedAccreditationData(address investor) external view onlyRegulatoryAuthority returns (bytes32, uint256) {
        require(investor != address(0), "Invalid investor address");
        Accreditation memory accreditation = _accreditations[investor];
        require(accreditation.encryptedDataHash != bytes32(0), "Accreditation data not found");

        return (accreditation.encryptedDataHash, accreditation.expirationDate);
    }

    // Function to check if an investor is accredited (public view)
    function isAccredited(address investor) external view returns (bool) {
        return _accreditedInvestors.contains(investor) && _accreditations[investor].expirationDate > block.timestamp;
    }

    // Function to get the total number of accredited investors
    function getAccreditedInvestorCount() external view returns (uint256) {
        return _accreditedInvestors.length();
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
