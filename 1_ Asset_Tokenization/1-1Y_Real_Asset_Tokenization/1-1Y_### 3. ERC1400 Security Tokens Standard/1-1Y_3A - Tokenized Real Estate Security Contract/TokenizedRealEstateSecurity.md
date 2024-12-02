### Smart Contract: `TokenizedRealEstateSecurity.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

/// @title Tokenized Real Estate Security Contract
/// @notice Tokenizes real estate as a security, allowing for fractional ownership of the property. Investors can trade the tokens, which represent shares of the real estate, while ensuring compliance with security regulations.
/// @dev Inherits ERC1400 standard to provide partitioning, compliance, and security features for security tokens.
contract TokenizedRealEstateSecurity is ERC1400, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");

    // KYC whitelist mapping
    mapping(address => bool) private _kycApproved;

    // Compliance parameters
    bool public complianceEnabled = true;

    // Events
    event KYCApproved(address indexed investor);
    event KYCRevoked(address indexed investor);
    event ComplianceStatusChanged(bool status);

    /// @dev Constructor to set up the initial values and roles
    /// @param name Name of the security token (e.g., "Real Estate Token")
    /// @param symbol Symbol of the security token (e.g., "RET")
    /// @param partitions Array of partition names for ERC1400 compliance
    constructor(
        string memory name,
        string memory symbol,
        bytes32[] memory partitions
    ) ERC1400(name, symbol, partitions) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
    }

    /// @notice Function to approve an investor's KYC status
    /// @param investor Address of the investor
    /// @dev Only accounts with the ADMIN_ROLE can approve KYC
    function approveKYC(address investor) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _kycApproved[investor] = true;
        emit KYCApproved(investor);
    }

    /// @notice Function to revoke an investor's KYC status
    /// @param investor Address of the investor
    /// @dev Only accounts with the ADMIN_ROLE can revoke KYC
    function revokeKYC(address investor) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _kycApproved[investor] = false;
        emit KYCRevoked(investor);
    }

    /// @notice Function to check if an investor is KYC approved
    /// @param investor Address of the investor
    /// @return Boolean indicating whether the investor is KYC approved
    function isKYCApproved(address investor) public view returns (bool) {
        return _kycApproved[investor];
    }

    /// @notice Function to enable or disable compliance checks
    /// @param status Boolean indicating the compliance status (true to enable, false to disable)
    /// @dev Only accounts with the ADMIN_ROLE can change compliance status
    function setComplianceStatus(bool status) external onlyRole(ADMIN_ROLE) whenNotPaused {
        complianceEnabled = status;
        emit ComplianceStatusChanged(status);
    }

    /// @notice Function to mint new security tokens to an investor
    /// @param to Address of the investor to mint tokens to
    /// @param amount Number of tokens to mint
    /// @param data Additional data for compliance checks
    /// @dev Only accounts with the ISSUER_ROLE can mint new tokens
    function issueSecurityTokens(
        address to,
        uint256 amount,
        bytes memory data
    ) external onlyRole(ISSUER_ROLE) nonReentrant whenNotPaused {
        require(_kycApproved[to], "Investor is not KYC approved");
        _mint(to, amount, data);
    }

    /// @notice Function to redeem security tokens from an investor
    /// @param from Address of the investor to redeem tokens from
    /// @param amount Number of tokens to redeem
    /// @param data Additional data for compliance checks
    /// @dev Only accounts with the ISSUER_ROLE can redeem tokens
    function redeemSecurityTokens(
        address from,
        uint256 amount,
        bytes memory data
    ) external onlyRole(ISSUER_ROLE) nonReentrant whenNotPaused {
        _burn(from, amount, data);
    }

    /// @notice Function to transfer tokens between two investors
    /// @param from Address of the sender
    /// @param to Address of the receiver
    /// @param amount Number of tokens to transfer
    /// @param data Additional data for compliance checks
    /// @dev Overrides ERC1400 transfer function to include KYC and compliance checks
    function transferFrom(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) public override whenNotPaused returns (bool) {
        require(_kycApproved[from], "Sender is not KYC approved");
        require(_kycApproved[to], "Receiver is not KYC approved");
        if (complianceEnabled) {
            require(_checkCompliance(from, to, amount), "Transfer not compliant");
        }
        return super.transferFrom(from, to, amount, data);
    }

    /// @dev Internal function to check compliance for token transfers
    /// @param from Address of the sender
    /// @param to Address of the receiver
    /// @param amount Number of tokens to transfer
    /// @return Boolean indicating whether the transfer is compliant
    function _checkCompliance(
        address from,
        address to,
        uint256 amount
    ) internal view returns (bool) {
        // Add custom compliance logic here
        return true;
    }

    /// @notice Function to pause the contract
    /// @dev Only accounts with ADMIN_ROLE can pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Function to unpause the contract
    /// @dev Only accounts with ADMIN_ROLE can unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1400, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

### Key Features of the Contract:

1. **ERC1400 Security Tokens Standard**:
   - Adheres to ERC1400 standard for tokenized securities with support for partitioning and compliance checks.
   - Provides fractional ownership of real estate assets as tradable security tokens.

2. **KYC/AML Integration**:
   - `approveKYC` and `revokeKYC`: Allows admins to approve or revoke KYC status for investors.
   - `isKYCApproved`: Checks if an investor is KYC-approved before allowing token transfers.

3. **Compliance Enforcement**:
   - `setComplianceStatus`: Enables or disables compliance checks.
   - `_checkCompliance`: Custom function to enforce compliance during token transfers.

4. **Token Issuance and Redemption**:
   - `issueSecurityTokens`: Mints new security tokens to investors with KYC approval.
   - `redeemSecurityTokens`: Redeems tokens from investors, removing them from circulation.

5. **Role-Based Access Control**:
   - **ADMIN_ROLE**: Admins can manage KYC and compliance settings.
   - **ISSUER_ROLE**: Issuers can mint and redeem security tokens.
   - **INVESTOR_ROLE**: Placeholder role for future use.

6. **Emergency Pausing and Security**:
   - The contract can be paused and unpaused by accounts with the `ADMIN_ROLE`.
   - `Pausable`: Allows freezing of contract functionalities in case of emergency.
   - `ReentrancyGuard`: Prevents reentrancy attacks during token issuance and redemption.

7. **Event Logging**:
   - `KYCApproved`: Emitted when an investor's KYC is approved.
   - `KYCRevoked`: Emitted when an investor's KYC is revoked.
   - `ComplianceStatusChanged`: Emitted when compliance status is changed.
  
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
   Create a deployment script for the contract using a tool like Hardhat or Truffle. Use the following template:

   ```javascript
   // deployment script using Hardhat

   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     const partitions = [ethers.utils.formatBytes32String("default")]; // Default partition
     const name = "Tokenized Real Estate Security";
     const symbol = "TRES";

     const TokenizedRealEstateSecurity = await ethers.getContractFactory("TokenizedRealEstateSecurity");
     const tokenizedRealEstateSecurity = await Tokenized

RealEstateSecurity.deploy(name, symbol, partitions);

     console.log("TokenizedRealEstateSecurity deployed to:", tokenizedRealEstateSecurity.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

   Deploy the contract using Hardhat:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

### Test Suite:

1. **Unit Tests**:
   - Test KYC approval and revocation.
   - Test token issuance and redemption with KYC-approved and non-approved investors.
   - Test compliance checks during token transfers.

2. **Gas Profiling**:
   - Measure gas consumption for minting, burning, and transferring tokens.
   - Optimize for gas efficiency.

3. **Security Checks**:
   - Run security checks using tools like MythX or CertiK for vulnerabilities.
   - Test against reentrancy and overflow/underflow vulnerabilities.

4. **API Documentation**:
   - Document all public functions, events, and modifiers for easy integration.

This smart contract is designed to facilitate secure and compliant fractional ownership of real estate assets, adhering to the ERC1400 standard for security tokens.