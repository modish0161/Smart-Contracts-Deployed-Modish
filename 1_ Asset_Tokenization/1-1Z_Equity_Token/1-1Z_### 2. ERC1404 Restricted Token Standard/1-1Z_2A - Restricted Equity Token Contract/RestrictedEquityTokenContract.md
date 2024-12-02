### Smart Contract: `RestrictedEquityTokenContract.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Restricted Equity Token Contract (ERC1404)
/// @notice This contract represents equity tokens with built-in transfer restrictions based on regulatory requirements.
contract RestrictedEquityTokenContract is ERC20, AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store the transfer restrictions for each address
    mapping(address => bool) private whitelist;
    mapping(address => bool) private blacklist;

    // Events for compliance actions
    event Whitelisted(address indexed account, bool status);
    event Blacklisted(address indexed account, bool status);
    event TransferBlocked(address indexed from, address indexed to, uint256 value, string reason);

    /// @notice Constructor to initialize the ERC20 token with details
    /// @param name Name of the equity token
    /// @param symbol Symbol of the equity token
    /// @param initialSupply Initial supply of the tokens to be minted to the deployer
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);

        _mint(msg.sender, initialSupply);
    }

    /// @notice Add or remove an address from the whitelist
    /// @param account Address to be whitelisted or removed from the whitelist
    /// @param status True to whitelist, false to remove
    function setWhitelist(address account, bool status) external onlyRole(COMPLIANCE_ROLE) {
        whitelist[account] = status;
        emit Whitelisted(account, status);
    }

    /// @notice Add or remove an address from the blacklist
    /// @param account Address to be blacklisted or removed from the blacklist
    /// @param status True to blacklist, false to remove
    function setBlacklist(address account, bool status) external onlyRole(COMPLIANCE_ROLE) {
        blacklist[account] = status;
        emit Blacklisted(account, status);
    }

    /// @notice Checks if an address is whitelisted
    /// @param account Address to be checked
    /// @return Boolean indicating whether the address is whitelisted
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }

    /// @notice Checks if an address is blacklisted
    /// @param account Address to be checked
    /// @return Boolean indicating whether the address is blacklisted
    function isBlacklisted(address account) external view returns (bool) {
        return blacklist[account];
    }

    /// @notice Override transfer function to include transfer restrictions
    /// @param recipient Address to receive the tokens
    /// @param amount Amount of tokens to be transferred
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(whitelist[msg.sender], "RestrictedEquityTokenContract: Sender not whitelisted");
        require(whitelist[recipient], "RestrictedEquityTokenContract: Recipient not whitelisted");
        require(!blacklist[msg.sender], "RestrictedEquityTokenContract: Sender blacklisted");
        require(!blacklist[recipient], "RestrictedEquityTokenContract: Recipient blacklisted");

        return super.transfer(recipient, amount);
    }

    /// @notice Override transferFrom function to include transfer restrictions
    /// @param sender Address sending the tokens
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to be transferred
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(whitelist[sender], "RestrictedEquityTokenContract: Sender not whitelisted");
        require(whitelist[recipient], "RestrictedEquityTokenContract: Recipient not whitelisted");
        require(!blacklist[sender], "RestrictedEquityTokenContract: Sender blacklisted");
        require(!blacklist[recipient], "RestrictedEquityTokenContract: Recipient blacklisted");

        return super.transferFrom(sender, recipient, amount);
    }

    /// @notice Pauses the contract (only by admin)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract (only by admin)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Mint new tokens to a specified address (only by admin)
    /// @param account Address to receive the new tokens
    /// @param amount Amount of tokens to be minted
    function mint(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _mint(account, amount);
    }

    /// @notice Burn tokens from a specified address (only by admin)
    /// @param account Address to burn the tokens from
    /// @param amount Amount of tokens to be burned
    function burn(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _burn(account, amount);
    }

    /// @notice Block token transfers if the contract is paused
    /// @param from Address sending the tokens
    /// @param to Address receiving the tokens
    /// @param amount Amount of tokens being transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (!whitelist[from] || !whitelist[to]) {
            emit TransferBlocked(from, to, amount, "Transfer not allowed: Not whitelisted");
            revert("RestrictedEquityTokenContract: Transfer not allowed: Not whitelisted");
        }

        if (blacklist[from] || blacklist[to]) {
            emit TransferBlocked(from, to, amount, "Transfer not allowed: Blacklisted");
            revert("RestrictedEquityTokenContract: Transfer not allowed: Blacklisted");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}
```

### Key Features of the Contract:

1. **Access Control and Roles**:
   - `ADMIN_ROLE`: Full administrative control, including pausing, minting, burning, and managing the contract.
   - `COMPLIANCE_ROLE`: Manages compliance-related tasks, including whitelisting and blacklisting.

2. **Whitelist and Blacklist Mechanism**:
   - `setWhitelist(address, bool)`: Adds or removes an address from the whitelist, allowing or denying access to token transfers.
   - `setBlacklist(address, bool)`: Adds or removes an address from the blacklist, blocking or unblocking the address from token transfers.

3. **Transfer Restrictions**:
   - `transfer()` and `transferFrom()`: Overridden functions to enforce whitelisting and blacklisting rules before any transfer is executed.
   - `_beforeTokenTransfer()`: Ensures that transfers can only occur between whitelisted addresses and that no transfers can occur from or to blacklisted addresses.

4. **Pausable Contract**:
   - The contract can be paused or unpaused by an admin to prevent transfers in case of emergencies.

5. **Minting and Burning**:
   - `mint(address, uint256)`: Allows the admin to mint new tokens to any specified address.
   - `burn(address, uint256)`: Allows the admin to burn tokens from any specified address.

6. **Event Logging**:
   - Events are emitted for compliance actions like whitelisting, blacklisting, and blocked transfers.

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

     const RestrictedEquityTokenContract = await ethers.getContractFactory("RestrictedEquityTokenContract");
     const equityToken = await RestrictedEquityTokenContract.deploy("Restricted Equity Token", "RET", ethers.utils.parseEther("1000000"));
     await equityToken.deployed();

     console.log("Restricted Equity Token Contract deployed to:", equityToken.address);
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
   - Write unit tests to verify transfer restrictions, compliance roles, and administrative controls.
   - Perform security audits to validate the transfer restrictions and the effectiveness of whitelisting and blacklisting.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

### Next Steps:

1. **Advanced Compliance Checks**:
   - Integrate with third-party compliance services for real-time checks on transfers.
   - Implement DAML integration for streamlined compliance workflows.

2. **User

 Interface**:
   - Build a frontend interface for admins to manage whitelisting and blacklisting.
   - Create dashboards for token holders to view compliance statuses.

3. **Security Audits**:
   - Conduct third-party security audits to ensure the contract meets industry standards.

This contract provides a comprehensive solution for issuing and managing restricted equity tokens, ensuring regulatory compliance through built-in transfer restrictions. It is flexible enough to support future upgrades and additional compliance requirements.