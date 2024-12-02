// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Accredited Investor Verification Contract for Real Asset Tokenization
/// @notice This contract uses AnonCreds for privacy-preserving verification of accredited investors.
contract AccreditedInvestorVerification is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Counter for credential IDs
    Counters.Counter private _credentialIds;

    // Structure to store investor credentials
    struct Credential {
        address investor;
        bytes32 hashedInfo;  // Privacy-preserving hash of the investor's accredited status information
        bool isAccredited;
    }

    // Mapping from credential ID to Credential details
    mapping(uint256 => Credential) private _credentials;

    // Mapping from investor address to credential ID
    mapping(address => uint256) private _investorToCredential;

    // Event emitted when a new credential is issued
    event CredentialIssued(uint256 indexed credentialId, address indexed investor);

    // Event emitted when a credential is verified
    event CredentialVerified(uint256 indexed credentialId, address indexed investor, bool isAccredited);

    // Modifier to check if the caller is the verified owner of the credential
    modifier onlyCredentialOwner(uint256 credentialId) {
        require(_credentials[credentialId].investor == msg.sender, "Caller is not the credential owner");
        _;
    }

    /// @notice Issue a new credential to an accredited investor
    /// @param investor Address of the investor
    /// @param hashedInfo Privacy-preserving hash of the investor's accredited status information
    function issueCredential(address investor, bytes32 hashedInfo) external onlyOwner nonReentrant {
        require(_investorToCredential[investor] == 0, "Investor already has a credential");

        _credentialIds.increment();
        uint256 newCredentialId = _credentialIds.current();

        _credentials[newCredentialId] = Credential({
            investor: investor,
            hashedInfo: hashedInfo,
            isAccredited: true
        });

        _investorToCredential[investor] = newCredentialId;

        emit CredentialIssued(newCredentialId, investor);
    }

    /// @notice Verify the accreditation status of an investor
    /// @param credentialId ID of the credential to verify
    /// @param hashedInfo Privacy-preserving hash of the investor's accredited status information
    function verifyCredential(uint256 credentialId, bytes32 hashedInfo) external view onlyCredentialOwner(credentialId) returns (bool) {
        Credential memory credential = _credentials[credentialId];
        require(credential.hashedInfo == hashedInfo, "Invalid hashed information");

        emit CredentialVerified(credentialId, credential.investor, credential.isAccredited);

        return credential.isAccredited;
    }

    /// @notice Revoke a credential from an investor
    /// @param credentialId ID of the credential to revoke
    function revokeCredential(uint256 credentialId) external onlyOwner {
        Credential memory credential = _credentials[credentialId];
        require(credential.isAccredited, "Credential is already revoked");

        _credentials[credentialId].isAccredited = false;

        emit CredentialVerified(credentialId, credential.investor, false);
    }

    /// @notice Retrieve the credential ID for a given investor
    /// @param investor Address of the investor
    /// @return credentialId ID of the credential
    function getCredentialId(address investor) external view returns (uint256) {
        require(_investorToCredential[investor] != 0, "Investor does not have a credential");
        return _investorToCredential[investor];
    }

    /// @notice Retrieve the accreditation status of a credential
    /// @param credentialId ID of the credential
    /// @return isAccredited Accreditation status of the credential
    function isAccredited(uint256 credentialId) external view returns (bool) {
        return _credentials[credentialId].isAccredited;
    }

    /// @notice Retrieve the total number of credentials issued
    /// @return totalCredentials Total number of credentials
    function totalCredentials() external view returns (uint256) {
        return _credentialIds.current();
    }

    /// @notice Allows the contract owner to update the accreditation status
    /// @param credentialId ID of the credential to update
    /// @param isAccredited New accreditation status
    function updateAccreditationStatus(uint256 credentialId, bool isAccredited) external onlyOwner {
        _credentials[credentialId].isAccredited = isAccredited;
        emit CredentialVerified(credentialId, _credentials[credentialId].investor, isAccredited);
    }
}
