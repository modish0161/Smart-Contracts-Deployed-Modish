// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Accredited Investor Verification Contract
/// @dev This contract uses AnonCreds-like privacy-preserving credentials to verify whether an investor meets accredited investor status.
contract AccreditedInvestorVerification is AccessControl, Ownable, ReentrancyGuard {
    // Role definitions for access control
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    // Structure to store investor credentials
    struct InvestorCredentials {
        bool isAccredited; // Investor accreditation status
        bytes32 credentialsHash; // Hash of the anonymized credentials
    }

    // Mapping to store verified investor addresses
    mapping(address => InvestorCredentials) private investorData;

    // Events for logging
    event InvestorVerified(address indexed investor, bool isAccredited);
    event InvestorCredentialsUpdated(address indexed investor, bytes32 newCredentialsHash);

    /// @notice Constructor to initialize the contract with the owner and default admin roles
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VERIFIER_ROLE, msg.sender);
    }

    /// @notice Function to add or update an investor's verification status and credentials
    /// @param investor Address of the investor
    /// @param isAccredited Boolean indicating whether the investor is accredited
    /// @param credentialsHash Hash of the anonymized credentials for verification
    /// @dev Only accounts with the VERIFIER_ROLE can call this function
    function verifyInvestor(
        address investor,
        bool isAccredited,
        bytes32 credentialsHash
    ) external onlyRole(VERIFIER_ROLE) nonReentrant {
        investorData[investor] = InvestorCredentials(isAccredited, credentialsHash);
        emit InvestorVerified(investor, isAccredited);
    }

    /// @notice Function to update an investor's credentials
    /// @param investor Address of the investor
    /// @param newCredentialsHash New hash of the anonymized credentials for verification
    /// @dev Only accounts with the VERIFIER_ROLE can call this function
    function updateInvestorCredentials(
        address investor,
        bytes32 newCredentialsHash
    ) external onlyRole(VERIFIER_ROLE) nonReentrant {
        require(investorData[investor].isAccredited, "Investor is not verified as accredited");
        investorData[investor].credentialsHash = newCredentialsHash;
        emit InvestorCredentialsUpdated(investor, newCredentialsHash);
    }

    /// @notice Function to get the accreditation status and credentials hash of an investor
    /// @param investor Address of the investor
    /// @return isAccredited Boolean indicating whether the investor is accredited
    /// @return credentialsHash Hash of the anonymized credentials
    function getInvestorData(address investor)
        external
        view
        returns (bool isAccredited, bytes32 credentialsHash)
    {
        InvestorCredentials memory data = investorData[investor];
        return (data.isAccredited, data.credentialsHash);
    }

    /// @notice Function to remove an investor's verification data
    /// @param investor Address of the investor
    /// @dev Only accounts with the VERIFIER_ROLE can call this function
    function removeInvestorVerification(address investor) external onlyRole(VERIFIER_ROLE) nonReentrant {
        delete investorData[investor];
    }

    /// @notice Override supportsInterface to include additional interfaces
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
