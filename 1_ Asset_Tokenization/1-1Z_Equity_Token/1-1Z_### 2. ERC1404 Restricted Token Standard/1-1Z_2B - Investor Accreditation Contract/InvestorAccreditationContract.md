### Smart Contract: `InvestorAccreditationContract.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Investor Accreditation Contract (ERC1404)
/// @notice This contract represents equity tokens with built-in accreditation verification for investors.
contract InvestorAccreditationContract is ERC20, AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store the accreditation status for each address
    mapping(address => bool) private accreditedInvestors;
    mapping(address => bool) private blacklistedInvestors;

    // Events for accreditation and compliance actions
    event InvestorAccredited(address indexed account, bool status);
    event InvestorBlacklisted(address indexed account, bool status);
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

    /// @notice Add or remove an address from the accredited investor list
    /// @param account Address to be accredited or removed from the accreditation list
    /// @param status True to accredit, false to remove
    function setAccreditedInvestor(address account, bool status) external onlyRole(COMPLIANCE_ROLE) {
        accreditedInvestors[account] = status;
        emit InvestorAccredited(account, status);
    }

    /// @notice Add or remove an address from the blacklist
    /// @param account Address to be blacklisted or removed from the blacklist
    /// @param status True to blacklist, false to remove
    function setBlacklistedInvestor(address account, bool status) external onlyRole(COMPLIANCE_ROLE) {
        blacklistedInvestors[account] = status;
        emit InvestorBlacklisted(account, status);
    }

    /// @notice Checks if an address is accredited
    /// @param account Address to be checked
    /// @return Boolean indicating whether the address is accredited
    function isAccreditedInvestor(address account) external view returns (bool) {
        return accreditedInvestors[account];
    }

    /// @notice Checks if an address is blacklisted
    /// @param account Address to be checked
    /// @return Boolean indicating whether the address is blacklisted
    function isBlacklistedInvestor(address account) external view returns (bool) {
        return blacklistedInvestors[account];
    }

    /// @notice Override transfer function to include accreditation and compliance checks
    /// @param recipient Address to receive the tokens
    /// @param amount Amount of tokens to be transferred
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(accreditedInvestors[msg.sender], "InvestorAccreditationContract: Sender not accredited");
        require(accreditedInvestors[recipient], "InvestorAccreditationContract: Recipient not accredited");
        require(!blacklistedInvestors[msg.sender], "InvestorAccreditationContract: Sender blacklisted");
        require(!blacklistedInvestors[recipient], "InvestorAccreditationContract: Recipient blacklisted");

        return super.transfer(recipient, amount);
    }

    /// @notice Override transferFrom function to include accreditation and compliance checks
    /// @param sender Address sending the tokens
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to be transferred
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(accreditedInvestors[sender], "InvestorAccreditationContract: Sender not accredited");
        require(accreditedInvestors[recipient], "InvestorAccreditationContract: Recipient not accredited");
        require(!blacklistedInvestors[sender], "InvestorAccreditationContract: Sender blacklisted");
        require(!blacklistedInvestors[recipient], "InvestorAccreditationContract: Recipient blacklisted");

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

    /// @notice Block token transfers if the contract is paused or sender/recipient not accredited
    /// @param from Address sending the tokens
    /// @param to Address receiving the tokens
    /// @param amount Amount of tokens being transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (!accreditedInvestors[from] || !accreditedInvestors[to]) {
            emit TransferBlocked(from, to, amount, "Transfer not allowed: Investor not accredited");
            revert("InvestorAccreditationContract: Transfer not allowed: Investor not accredited");
        }

        if (blacklistedInvestors[from] || blacklistedInvestors[to]) {
            emit TransferBlocked(from, to, amount, "Transfer not allowed: Blacklisted");
            revert("InvestorAccreditationContract: Transfer not allowed: Blacklisted");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}
```

### Key Features of the Contract:

1. **Access Control and Roles**:
   - `ADMIN_ROLE`: Full administrative control, including pausing, minting, burning, and managing the contract.
   - `COMPLIANCE_ROLE`: Manages compliance-related tasks, including accrediting investors and blacklisting addresses.

2. **Accreditation and Blacklist Mechanism**:
   - `setAccreditedInvestor(address, bool)`: Adds or removes an address from the accredited investor list, allowing or denying them access to equity tokens.
   - `setBlacklistedInvestor(address, bool)`: Adds or removes an address from the blacklist, blocking or unblocking the address from token transfers.

3. **Transfer Restrictions**:
   - `transfer()` and `transferFrom()`: Overridden functions to enforce accreditation and compliance rules before any transfer is executed.
   - `_beforeTokenTransfer()`: Ensures that transfers can only occur between accredited addresses and that no transfers can occur from or to blacklisted addresses.

4. **Pausable Contract**:
   - The contract can be paused or unpaused by an admin to prevent transfers in case of emergencies.

5. **Minting and Burning**:
   - `mint(address, uint256)`: Allows the admin to mint new tokens to any specified address.
   - `burn(address, uint256)`: Allows the admin to burn tokens from any specified address.

6. **Event Logging**:
   - Events are emitted for accreditation, blacklisting actions, and blocked transfers.

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

     const InvestorAccreditationContract = await ethers.getContractFactory("InvestorAccreditationContract");
     const equityToken = await InvestorAccreditationContract.deploy("Accredited Equity Token", "AET", ethers.utils.parseEther("1000000"));
     await equityToken.deployed();

     console.log("Investor Accreditation Contract deployed to:", equityToken.address);
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
   - Write unit tests to verify investor accreditation, compliance roles, and administrative controls.
   - Perform security audits to validate the transfer restrictions and the effectiveness of the accreditation process.

6. **API Documentation**:
   -

 Create API documentation using a tool like `solidity-docgen` to generate detailed descriptions of the contract's functions and events.

This contract provides a robust solution for managing investor accreditation while ensuring compliance with the ERC1404 restricted token standard. It can be integrated into larger security token ecosystems or used independently for specific equity offerings.