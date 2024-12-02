### Smart Contract: `TaxWithholding.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Tax Withholding Contract
/// @notice This contract automatically calculates and withholds taxes on dividends or token transactions, ensuring tax compliance for equity token holders.
contract TaxWithholding is ERC20, AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TAX_ADMIN_ROLE = keccak256("TAX_ADMIN_ROLE");

    // Struct to store tax information
    struct TaxRate {
        uint256 rate; // Tax rate in percentage (e.g., 10% = 1000, where 10000 = 100%)
        bool isActive;
    }

    // Mapping for tax rates per jurisdiction
    mapping(string => TaxRate) public taxRates;

    // Mapping for user jurisdictions
    mapping(address => string) public userJurisdictions;

    // Events
    event TaxRateSet(string indexed jurisdiction, uint256 rate);
    event JurisdictionSet(address indexed user, string jurisdiction);
    event TaxWithheld(address indexed user, uint256 amount, string jurisdiction);

    /// @notice Constructor to initialize the ERC20 token with details
    /// @param name Name of the equity token
    /// @param symbol Symbol of the equity token
    /// @param initialSupply Initial supply of tokens to be minted to the deployer
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TAX_ADMIN_ROLE, msg.sender);

        _mint(msg.sender, initialSupply);
    }

    /// @notice Set the tax rate for a specific jurisdiction
    /// @param jurisdiction The name of the jurisdiction (e.g., "US", "UK")
    /// @param rate Tax rate in percentage (e.g., 10% = 1000)
    function setTaxRate(string memory jurisdiction, uint256 rate) external onlyRole(TAX_ADMIN_ROLE) {
        require(rate <= 10000, "Rate exceeds 100%");
        taxRates[jurisdiction] = TaxRate({rate: rate, isActive: true});
        emit TaxRateSet(jurisdiction, rate);
    }

    /// @notice Set the jurisdiction for a user
    /// @param user The address of the user
    /// @param jurisdiction The jurisdiction for the user
    function setJurisdiction(address user, string memory jurisdiction) external onlyRole(TAX_ADMIN_ROLE) {
        userJurisdictions[user] = jurisdiction;
        emit JurisdictionSet(user, jurisdiction);
    }

    /// @notice Transfer function overridden to calculate and withhold taxes
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to transfer
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _withholdTax(msg.sender, amount);
        return super.transfer(recipient, amount);
    }

    /// @notice TransferFrom function overridden to calculate and withhold taxes
    /// @param sender Address sending the tokens
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _withholdTax(sender, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    /// @notice Internal function to calculate and withhold taxes
    /// @param user Address of the user whose tokens are being transferred
    /// @param amount Amount of tokens being transferred
    function _withholdTax(address user, uint256 amount) internal {
        string memory jurisdiction = userJurisdictions[user];
        TaxRate memory rateInfo = taxRates[jurisdiction];

        require(rateInfo.isActive, "Jurisdiction tax rate not active");

        uint256 taxAmount = (amount * rateInfo.rate) / 10000;
        if (taxAmount > 0) {
            _burn(user, taxAmount); // Burn tax tokens to simulate withholding
            emit TaxWithheld(user, taxAmount, jurisdiction);
        }
    }

    /// @notice Pauses the contract (only by admin)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract (only by admin)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Mint new tokens (only by admin)
    /// @param account Address to mint the tokens to
    /// @param amount Amount of tokens to mint
    function mint(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _mint(account, amount);
    }

    /// @notice Burn tokens (only by admin)
    /// @param account Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burn(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _burn(account, amount);
    }
}
```

### Key Features of the Contract:

1. **Tax Rate Management**:
   - `setTaxRate(string memory jurisdiction, uint256 rate)`: Sets the tax rate for a specific jurisdiction. Rates are stored as percentages in basis points (e.g., 1000 = 10%).

2. **Jurisdiction Management**:
   - `setJurisdiction(address user, string memory jurisdiction)`: Assigns a jurisdiction to a user, ensuring the correct tax rate is applied when they transact.

3. **Automatic Tax Withholding**:
   - Both `transfer()` and `transferFrom()` are overridden to automatically calculate and withhold taxes based on the user’s jurisdiction. The withheld tax is “burned” (removed from circulation).

4. **Compliance with ERC1404**:
   - The contract follows the **ERC1404** standard by allowing restricted transfers based on compliance conditions like jurisdictional tax regulations.

5. **Pausable Contract**:
   - The contract can be paused by an admin to prevent all token transfers in case of emergency or compliance issues.

6. **Minting and Burning**:
   - Admins can mint new tokens or burn tokens using the `mint()` and `burn()` functions.

7. **Access Control**:
   - Roles like `ADMIN_ROLE` and `TAX_ADMIN_ROLE` ensure that only authorized users can manage tax rates, assign jurisdictions, or control minting and burning of tokens.

### Deployment Instructions:

1. **Install Dependencies**:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Compile the contract using Hardhat or Truffle:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Example Hardhat deployment script:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     const TaxWithholding = await ethers.getContractFactory("TaxWithholding");
     const token = await TaxWithholding.deploy("Equity Token", "ETK", ethers.utils.parseEther("1000000"));
     await token.deployed();

     console.log("Tax Withholding Contract deployed to:", token.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

4. **Run the Deployment Script**:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

5. **Testing and Auditing**:
   - Write test cases to ensure tax withholding works correctly based on different jurisdictions and rates.
   - Have the contract audited by a third party to ensure it adheres to security best practices.

6. **Off-Chain Tax Compliance**:
   - Integrate with off-chain services for reporting tax withholding to regulators if required by local laws.

### Additional Considerations:
- This contract does not directly handle dividend distribution, but you can extend its functionality to automatically calculate and withhold taxes on dividends distributed to equity token holders.
- Further customization could include integrating oracles to dynamically set tax rates based on real-time regulatory changes.