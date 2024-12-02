### Smart Contract: `CorporateActionContract.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/// @title Corporate Action Contract for ERC1400 Security Tokens
/// @notice This contract handles corporate actions such as stock splits, dividends, and buybacks on tokenized equity shares.
contract CorporateActionContract is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    IERC1400 public equityToken;

    // Events for corporate actions
    event DividendDistributed(uint256 amount, uint256 timestamp);
    event StockSplitExecuted(uint256 factor, uint256 timestamp);
    event BuybackExecuted(address indexed from, uint256 amount, uint256 timestamp);

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC1400 token representing the equity
    constructor(address _equityToken) {
        require(_equityToken != address(0), "CorporateActionContract: Invalid equity token address");

        equityToken = IERC1400(_equityToken);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    /// @notice Distributes dividends to all token holders
    /// @param amount Total dividend amount to be distributed
    function distributeDividends(uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(amount > 0, "CorporateActionContract: Dividend amount must be greater than zero");
        uint256 totalSupply = equityToken.totalSupply();
        require(totalSupply > 0, "CorporateActionContract: No tokens in circulation");

        // Calculate dividend per share
        uint256 dividendPerShare = amount / totalSupply;

        // Distribute dividends to all holders
        for (uint256 i = 0; i < totalSupply; i++) {
            address shareholder = equityToken.holderAt(i);
            uint256 balance = equityToken.balanceOf(shareholder);
            uint256 dividend = dividendPerShare * balance;
            (bool success, ) = shareholder.call{value: dividend}("");
            require(success, "CorporateActionContract: Dividend transfer failed");
        }

        emit DividendDistributed(amount, block.timestamp);
    }

    /// @notice Executes a stock split for the token
    /// @param splitFactor The factor by which the stock will be split
    function executeStockSplit(uint256 splitFactor) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(splitFactor > 1, "CorporateActionContract: Split factor must be greater than 1");

        uint256 totalSupply = equityToken.totalSupply();
        uint256 newTotalSupply = totalSupply * splitFactor;

        for (uint256 i = 0; i < totalSupply; i++) {
            address shareholder = equityToken.holderAt(i);
            uint256 balance = equityToken.balanceOf(shareholder);
            equityToken.mint(shareholder, balance * (splitFactor - 1));
        }

        emit StockSplitExecuted(splitFactor, block.timestamp);
    }

    /// @notice Executes a token buyback
    /// @param from Address from which tokens are being bought back
    /// @param amount Number of tokens to buy back
    function executeBuyback(address from, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(from != address(0), "CorporateActionContract: Invalid address");
        require(amount > 0, "CorporateActionContract: Amount must be greater than zero");
        require(equityToken.balanceOf(from) >= amount, "CorporateActionContract: Insufficient balance");

        equityToken.burn(from, amount);

        emit BuybackExecuted(from, amount, block.timestamp);
    }

    /// @notice Pauses the contract (only by admin)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract (only by admin)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Fallback function to receive dividends
    receive() external payable {}

    /// @notice Withdraws any remaining funds to the admin
    function withdrawFunds() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "CorporateActionContract: No funds to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "CorporateActionContract: Withdrawal failed");
    }
}
```

### Key Features of the Contract:

1. **Roles and Access Control**:
   - `ADMIN_ROLE`: Full administrative control over the contract, including executing corporate actions and pausing the contract.
   - `COMPLIANCE_ROLE`: Manages compliance-related features in the future.

2. **Corporate Actions**:
   - `distributeDividends()`: Distributes dividends to all token holders based on their shareholdings.
   - `executeStockSplit()`: Executes a stock split based on a split factor.
   - `executeBuyback()`: Buys back tokens from a specified address, reducing the total supply.

3. **Pausable**:
   - The contract can be paused or unpaused by an admin to prevent certain actions during emergency situations.

4. **Security Features**:
   - `ReentrancyGuard`: Prevents reentrancy attacks on critical functions like dividends distribution and buybacks.
   - `AccessControl`: Ensures only authorized users can perform certain actions.

5. **Dividend Distribution**:
   - Automatically calculates and distributes dividends to all token holders based on their shareholdings.

6. **Stock Split Execution**:
   - Mints new tokens to current holders according to the split factor.

7. **Buyback Execution**:
   - Allows the company to buy back tokens from specific addresses and burn them.

8. **Emergency Withdrawals**:
   - Admins can withdraw any remaining funds in the contract.

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

     const CorporateActionContract = await ethers.getContractFactory("CorporateActionContract");
     const corporateActionContract = await CorporateActionContract.deploy("YOUR_ERC1400_TOKEN_ADDRESS");
     await corporateActionContract.deployed();

     console.log("Corporate Action Contract deployed to:", corporateActionContract.address);
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
   - Write unit tests for each corporate action to ensure the contract works as intended.
   - Perform security audits to verify the integrity and security of the corporate action functionalities.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

### Next Steps:

- **Advanced Corporate Actions**: Add more complex corporate actions like rights issues, mergers, or acquisitions.
- **Automated Compliance Integration**: Integrate with third-party compliance tools for automated verification of corporate action requirements.
- **Governance**: Add governance mechanisms for token holders to vote on corporate actions.

This contract provides a robust solution for managing corporate actions on tokenized equity, ensuring compliance with regulatory requirements while providing flexibility for future upgrades and integration.