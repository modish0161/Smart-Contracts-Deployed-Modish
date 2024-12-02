### Smart Contract: `AccreditedInvestorVerification.sol`

```solidity
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
```

### Key Features of the Contract:

1. **AnonCreds-Like Privacy-Preserving Credentials**:
   - The contract uses privacy-preserving credential verification similar to AnonCreds to verify the accreditation status of investors.
   - Investor credentials are stored as anonymized hashes (`credentialsHash`) to maintain privacy.

2. **Role-Based Access Control**:
   - **VERIFIER_ROLE**: Allows authorized accounts to verify investors and update their credentials.
   - Only accounts with the `VERIFIER_ROLE` can verify investors or update their credentials.

3. **Investor Data Management**:
   - **verifyInvestor**: Adds or updates an investor's verification status and credentials.
   - **updateInvestorCredentials**: Allows authorized accounts to update the anonymized credentials of an already verified investor.
   - **getInvestorData**: Public function to view an investor's accreditation status and anonymized credentials hash.

4. **Security and Modularity**:
   - **Access Control**: Implements fine-grained control over contract roles using OpenZeppelin's `AccessControl`.
   - **NonReentrant**: Prevents reentrancy attacks using the `nonReentrant` modifier.

5. **Event Logging**:
   - **InvestorVerified**: Logs when an investor is verified or updated.
   - **InvestorCredentialsUpdated**: Logs when an investor's credentials are updated.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure you have OpenZeppelin contracts installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Use Hardhat or Truffle to compile the contract:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script for the contract:
   ```javascript
   async function main() {
       const [deployer] = await ethers.getSigners();
       console.log("Deploying contracts with the account:", deployer.address);

       const AccreditedInvestorVerification = await ethers.getContractFactory("AccreditedInvestorVerification");
       const contract = await AccreditedInvestorVerification.deploy();

       console.log("AccreditedInvestorVerification deployed to:", contract.address);
   }

   main()
       .then(() => process.exit(0))
       .catch(error => {
           console.error(error);
           process.exit(1);
       });
   ```

4. **Testing the Contract**:
   Write unit tests for all functionalities, including verifying investors, updating credentials, viewing investor data, and removing investor data.

5. **Verify on Etherscan (Optional)**:
   If deploying on a public network, verify the contract on Etherscan using:
   ```bash
   npx hardhat verify --network mainnet <deployed_contract_address>
   ```

### Additional Customizations:

1. **Integration with Off-Chain Systems**:
   Implement integration with off-chain systems using Chainlink oracles for dynamic verification of investor credentials.

2. **Custom Credential Verification Logic**:
   Implement custom logic for verifying investor credentials based on different criteria, including region-specific compliance rules.

3. **Enhanced Security**:
   Implement multi-signature approvals for critical functions or integrate with external compliance services for real-time KYC/AML checks.

4. **Upgradability**:
   Implement proxy patterns like the UUPS or Transparent Proxy pattern to enable future upgrades to the contract without redeploying it.

5. **Integration with Security Token Contracts**:
   Integrate with ERC1400 or ERC1404 security token contracts to enforce compliance during token transfers based on verified investor status.

This contract provides a robust foundation for privacy-preserving accredited investor verification, ensuring compliance and privacy for security token platforms.