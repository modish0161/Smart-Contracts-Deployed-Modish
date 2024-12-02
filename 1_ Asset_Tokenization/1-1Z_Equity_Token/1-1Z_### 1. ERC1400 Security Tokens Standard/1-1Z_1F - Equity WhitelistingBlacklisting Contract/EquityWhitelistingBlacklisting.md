### Smart Contract: `EquityWhitelistingBlacklisting.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Equity Whitelisting and Blacklisting Contract
/// @notice This contract manages whitelists and blacklists for equity token holders, ensuring that only verified or compliant entities can hold and trade equity tokens.
contract EquityWhitelistingBlacklisting is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    IERC1400 public equityToken;

    mapping(address => bool) private whitelist;
    mapping(address => bool) private blacklist;

    event AddressWhitelisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);

    modifier onlyWhitelisted(address account) {
        require(whitelist[account], "EquityWhitelistingBlacklisting: Address is not whitelisted");
        require(!blacklist[account], "EquityWhitelistingBlacklisting: Address is blacklisted");
        _;
    }

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC1400 token representing the equity
    constructor(address _equityToken) {
        require(_equityToken != address(0), "EquityWhitelistingBlacklisting: Invalid equity token address");

        equityToken = IERC1400(_equityToken);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    /// @notice Adds an address to the whitelist
    /// @param account Address to be added to the whitelist
    function addToWhitelist(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "EquityWhitelistingBlacklisting: Cannot add zero address to whitelist");
        whitelist[account] = true;
        emit AddressWhitelisted(account);
    }

    /// @notice Removes an address from the whitelist
    /// @param account Address to be removed from the whitelist
    function removeFromWhitelist(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "EquityWhitelistingBlacklisting: Cannot remove zero address from whitelist");
        whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    /// @notice Adds an address to the blacklist
    /// @param account Address to be added to the blacklist
    function addToBlacklist(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "EquityWhitelistingBlacklisting: Cannot add zero address to blacklist");
        blacklist[account] = true;
        emit AddressBlacklisted(account);
    }

    /// @notice Removes an address from the blacklist
    /// @param account Address to be removed from the blacklist
    function removeFromBlacklist(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "EquityWhitelistingBlacklisting: Cannot remove zero address from blacklist");
        blacklist[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }

    /// @notice Checks if an address is whitelisted
    /// @param account Address to be checked
    /// @return True if the address is whitelisted, false otherwise
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }

    /// @notice Checks if an address is blacklisted
    /// @param account Address to be checked
    /// @return True if the address is blacklisted, false otherwise
    function isBlacklisted(address account) external view returns (bool) {
        return blacklist[account];
    }

    /// @notice Function to pause the contract (only by admin)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Function to unpause the contract (only by admin)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Hook that is called before any transfer of tokens
    /// @dev This will check if the sender and receiver are whitelisted
    /// @param from Address from which tokens are transferred
    /// @param to Address to which tokens are transferred
    /// @param amount Amount of tokens transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal whenNotPaused {
        require(whitelist[from], "EquityWhitelistingBlacklisting: Sender is not whitelisted");
        require(!blacklist[from], "EquityWhitelistingBlacklisting: Sender is blacklisted");
        require(whitelist[to], "EquityWhitelistingBlacklisting: Receiver is not whitelisted");
        require(!blacklist[to], "EquityWhitelistingBlacklisting: Receiver is blacklisted");
    }
}
```

### Key Features of the Contract:

1. **Roles and Access Control**:
   - `ADMIN_ROLE`: Full administrative control over the contract.
   - `COMPLIANCE_ROLE`: Manages whitelisting and blacklisting of addresses.

2. **Whitelisting/Blacklisting**:
   - `addToWhitelist()`: Adds an address to the whitelist.
   - `removeFromWhitelist()`: Removes an address from the whitelist.
   - `addToBlacklist()`: Adds an address to the blacklist.
   - `removeFromBlacklist()`: Removes an address from the blacklist.
   - `isWhitelisted()`: Checks if an address is whitelisted.
   - `isBlacklisted()`: Checks if an address is blacklisted.

3. **Pausable**:
   - The contract can be paused or unpaused by an admin.

4. **Before Token Transfer Hook**:
   - `_beforeTokenTransfer()`: Hook function that checks if both the sender and receiver are whitelisted and not blacklisted before any token transfer. This ensures compliance.

### Deployment Instructions:

1. **Install Dependencies**:
   Install OpenZeppelin contracts:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Use Hardhat or Truffle to compile the contract:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script using Hardhat:

   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     const EquityToken = await ethers.getContractFactory("EquityToken");
     const equityToken = await EquityToken.deploy();
     await equityToken.deployed();

     console.log("Equity Token deployed to:", equityToken.address);

     const EquityWhitelistingBlacklisting = await ethers.getContractFactory("EquityWhitelistingBlacklisting");
     const equityWhitelistingBlacklisting = await EquityWhitelistingBlacklisting.deploy(equityToken.address);
     await equityWhitelistingBlacklisting.deployed();

     console.log("Equity Whitelisting and Blacklisting Contract deployed to:", equityWhitelistingBlacklisting.address);
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
   - Write unit tests for whitelisting and blacklisting functionalities.
   - Ensure compliance with security token transfer restrictions.
   - Perform security audits to verify the integrity and security of the whitelisting and blacklisting mechanisms.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

### Next Steps:

- **Advanced Compliance**: Implement additional compliance checks for more complex regulatory requirements.
- **Automated Compliance Integration**: Integrate with third-party compliance tools for automated verification of KYC/AML status.
- **Governance**: Add governance mechanisms for token holders to vote on whitelisting/blacklisting decisions.

This contract provides a robust solution for managing whitelists and blacklists for equity tokens, ensuring compliance with regulatory requirements while providing flexibility for future upgrades and integration.