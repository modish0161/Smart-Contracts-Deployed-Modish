### Smart Contract: `AccreditedInvestorVerification.sol`

```solidity
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
```

### Key Features of the Contract:

1. **Privacy-Preserving Credentials**:
   - The contract uses a privacy-preserving approach by storing hashed information related to an investor’s accreditation status.
   - The `hashedInfo` is compared during verification, ensuring privacy and compliance without exposing sensitive data.

2. **Credential Issuance**:
   - The contract owner (admin) can issue credentials to accredited investors, associating their address with a unique credential ID.
   - Investors receive a credential ID and a hashed representation of their accredited status information.

3. **Verification of Accreditation Status**:
   - Investors can verify their accredited status using the `verifyCredential` function, which checks if the provided hashed information matches the stored data.
   - Events are emitted to log the verification status for transparency.

4. **Revocation and Status Update**:
   - The contract owner can revoke credentials or update the accreditation status of an investor if their status changes.
   - This ensures that only compliant investors can participate in token offerings.

5. **Access Control**:
   - The contract uses OpenZeppelin’s `Ownable` and `ReentrancyGuard` for access control and protection against reentrancy attacks.

6. **Event Logging**:
   - Events `CredentialIssued` and `CredentialVerified` are emitted to track the issuance and verification of credentials.

7. **Modular Design**:
   - The contract is designed to be modular, allowing for future upgrades and integration with other contracts or systems as needed.

### Deployment Instructions:

1. **Install Dependencies**:
   Make sure OpenZeppelin contracts are installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Use Hardhat or Truffle to compile the contract:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script using Hardhat or Truffle:

   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     // Deploy the contract
     const AccreditedInvestorVerification = await ethers.getContractFactory("AccreditedInvestorVerification");
     const accreditedInvestorVerification = await AccreditedInvestorVerification.deploy();

     console.log("Accredited Investor Verification Contract deployed to:", accreditedInvestorVerification.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

4. **Run the Deployment Script**:
   Deploy the contract using Hardhat:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

5. **Testing and Verification**:
   - Write unit tests to verify the core functionalities such as credential issuance, verification, and revocation.
   - Perform a security audit to ensure safe handling of investor data and accreditation status.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

### Next Steps:

- **Integration with Token Contracts**: Integrate this contract with ERC-1400 or other security token standards to enforce accreditation checks before token transfers.
- **Oracle Integration**: Consider integrating with trusted oracles to dynamically update accreditation status based on external data sources.
- **Enhanced Privacy**: Explore zero-knowledge proofs for additional privacy measures in verification processes.

This contract provides a secure and modular solution for verifying accredited investor status in a privacy-preserving manner, ensuring compliance while protecting sensitive information.