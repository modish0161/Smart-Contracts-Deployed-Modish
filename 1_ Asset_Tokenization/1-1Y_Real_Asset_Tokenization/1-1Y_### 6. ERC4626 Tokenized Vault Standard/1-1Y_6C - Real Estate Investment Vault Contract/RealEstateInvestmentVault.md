### Smart Contract: `RealEstateInvestmentVault.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Real Estate Investment Vault Contract
/// @notice This contract tokenizes a vault containing multiple real estate properties.
///         Each vault token represents a share in the collective value of the assets stored within the vault.
contract RealEstateInvestmentVault is ERC4626, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Minimum investment required to participate in the vault
    uint256 public minInvestment;

    // ERC20 token used for the vault shares
    ERC20 private vaultToken;

    // Struct to store information about each real estate property in the vault
    struct Property {
        string name;
        string location;
        uint256 value;
    }

    // Mapping to store properties by ID
    mapping(uint256 => Property) public properties;

    // Counter for property IDs
    uint256 public propertyCount;

    // Events
    event VaultDeposit(address indexed investor, uint256 amount, uint256 shares);
    event VaultWithdrawal(address indexed investor, uint256 amount, uint256 shares);
    event MinimumInvestmentChanged(uint256 newMinInvestment);
    event PropertyAdded(uint256 propertyId, string name, string location, uint256 value);
    event PropertyValueUpdated(uint256 propertyId, uint256 newValue);

    /// @dev Constructor to set token details and initial minimum investment
    /// @param _vaultToken Address of the ERC20 token representing fractional ownership of the vault
    /// @param _minInvestment Minimum investment required to participate in the vault
    constructor(ERC20 _vaultToken, uint256 _minInvestment) ERC4626(_vaultToken, "Real Estate Investment Vault Share", "REIVS") {
        vaultToken = _vaultToken;
        minInvestment = _minInvestment;
    }

    /// @notice Deposit assets into the vault and receive vault shares
    /// @param assets The amount of assets to deposit
    /// @param receiver The address of the receiver of the shares
    /// @return shares The amount of shares received
    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256 shares) {
        require(assets >= minInvestment, "Investment amount is below minimum");
        shares = super.deposit(assets, receiver);
        emit VaultDeposit(receiver, assets, shares);
    }

    /// @notice Withdraw assets from the vault by burning shares
    /// @param shares The amount of shares to burn
    /// @param receiver The address of the receiver of the assets
    /// @param owner The address of the owner of the shares
    /// @return assets The amount of assets returned
    function withdraw(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256 assets) {
        assets = super.withdraw(shares, receiver, owner);
        emit VaultWithdrawal(receiver, assets, shares);
    }

    /// @notice Add a new property to the vault
    /// @param name The name of the property
    /// @param location The location of the property
    /// @param value The value of the property in vault tokens
    function addProperty(string memory name, string memory location, uint256 value) external onlyOwner {
        propertyCount++;
        properties[propertyCount] = Property(name, location, value);
        emit PropertyAdded(propertyCount, name, location, value);
    }

    /// @notice Update the value of an existing property in the vault
    /// @param propertyId The ID of the property to update
    /// @param newValue The new value of the property in vault tokens
    function updatePropertyValue(uint256 propertyId, uint256 newValue) external onlyOwner {
        require(propertyId > 0 && propertyId <= propertyCount, "Invalid property ID");
        properties[propertyId].value = newValue;
        emit PropertyValueUpdated(propertyId, newValue);
    }

    /// @notice Set a new minimum investment amount
    /// @param _minInvestment The new minimum investment amount
    function setMinInvestment(uint256 _minInvestment) external onlyOwner {
        minInvestment = _minInvestment;
        emit MinimumInvestmentChanged(_minInvestment);
    }

    /// @notice Calculate the total assets in the vault
    /// @return The total assets held in the vault
    function totalAssets() public view override returns (uint256) {
        return vaultToken.balanceOf(address(this));
    }

    /// @notice Convert a given amount of assets to shares
    /// @param assets The amount of assets to convert
    /// @return shares The equivalent shares
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        return super.convertToShares(assets);
    }

    /// @notice Convert a given amount of shares to assets
    /// @param shares The amount of shares to convert
    /// @return assets The equivalent assets
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        return super.convertToAssets(shares);
    }

    /// @notice Max deposit amount that can be made for a given receiver
    /// @param receiver The address of the receiver
    /// @return The maximum amount of assets that can be deposited
    function maxDeposit(address receiver) public view override returns (uint256) {
        return vaultToken.balanceOf(receiver);
    }

    /// @notice Max withdraw amount that can be made for a given owner
    /// @param owner The address of the owner
    /// @return The maximum amount of shares that can be withdrawn
    function maxWithdraw(address owner) public view override returns (uint256) {
        return maxRedeem(owner);
    }

    /// @notice Override required for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view override(ERC4626) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

### Key Features of the Contract:

1. **ERC4626 Tokenized Vault Standard**:
   - Manages a pool of tokenized assets (real estate properties) and provides ERC4626 standard functionalities for deposits and withdrawals.

2. **ERC20 Fungible Token Compatibility**:
   - Uses an ERC20 token (`vaultToken`) to represent shares in the real estate investment vault.
   - Investors can buy, sell, and trade these shares as fractional ownership of the real estate properties.

3. **Minimum Investment Requirement**:
   - `minInvestment` parameter ensures that only investments above a certain value are accepted.
   - The contract owner can update this value as necessary.

4. **Real Estate Property Management**:
   - The contract allows the addition of new properties with details like name, location, and value.
   - Property values can be updated by the contract owner, enabling accurate valuation of the vault's total assets.

5. **Deposits and Withdrawals**:
   - `deposit()`: Investors deposit assets into the vault and receive shares proportional to the value of their deposit.
   - `withdraw()`: Investors can redeem their shares for underlying assets stored in the vault.

6. **Access Control**:
   - Only the owner of the contract can update the minimum investment value and manage properties.

7. **Supports Interface for Multiple Standards**:
   - Complies with ERC4626 and other necessary standards for broader interoperability.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure OpenZeppelin contracts are installed:
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
   // deployment script using Hardhat

   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     // Parameters for deployment
     const vaultTokenAddress = "0xYourVaultTokenAddress"; // ERC20 token address representing shares
     const minInvestment = ethers.utils.parseUnits("500", 18); // Minimum investment

     // Deploy the contract
     const RealEstateInvestmentVault = await ethers.getContractFactory("RealEstateInvestmentVault");
     const vaultContract = await RealEstateInvestmentVault.deploy(vaultTokenAddress, minInvestment);

     console.log("Real Estate Investment Vault Contract deployed to:", vaultContract.address);
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
   - Write unit tests to verify the core functionalities such as deposits, withdrawals, and property management.
   - Perform a security audit to ensure safe handling of pooled assets.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

This contract allows for the secure and efficient management of a real estate-based vault, enabling investors to gain fractional ownership in a diversified pool of real estate assets. Adjust parameters like `minInvestment` as needed, and consider additional functionalities based on your specific use case.