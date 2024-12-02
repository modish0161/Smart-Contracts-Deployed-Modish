### Smart Contract: `RealAssetVaultContract.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

/// @title Real Asset Vault Contract
/// @notice Tokenizes a vault containing multiple real assets, such as property, commodities, or other tangible investments.
/// @dev Implements ERC4626 standard for tokenized vaults, with ERC20 for fractional ownership.
contract RealAssetVaultContract is ERC4626, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ERC20 token used for the vault (representing shares)
    ERC20 private vaultToken;

    // Minimum amount required to invest in the vault
    uint256 public minInvestment;

    // Events
    event VaultDeposit(address indexed investor, uint256 amount, uint256 shares);
    event VaultWithdrawal(address indexed investor, uint256 amount, uint256 shares);
    event MinimumInvestmentChanged(uint256 newMinInvestment);

    /// @dev Constructor to set token details and initial minimum investment
    /// @param _vaultToken Address of the ERC20 token representing fractional ownership of the vault
    /// @param _minInvestment Minimum investment required to participate in the vault
    constructor(ERC20 _vaultToken, uint256 _minInvestment) ERC4626(_vaultToken, "Real Asset Vault Share", "RAVS") {
        vaultToken = _vaultToken;
        minInvestment = _minInvestment;
    }

    /// @notice Deposit assets into the vault and receive shares
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
   - Manages pooled assets and tokenizes ownership using the ERC4626 standard.
   - Represents fractional ownership of a diversified portfolio of real assets.

2. **ERC20 Fungible Token Compatibility**:
   - Uses an ERC20 token (`vaultToken`) to represent shares in the vault.
   - Allows for fractional ownership and seamless trading of pooled assets.

3. **Minimum Investment Requirement**:
   - `minInvestment` ensures only significant investments are accepted.
   - Adjustable by the owner to control the entry barrier.

4. **Deposits and Withdrawals**:
   - `deposit()`: Investors deposit assets and receive proportional shares.
   - `withdraw()`: Investors can redeem their shares for the underlying assets.
   - Event logging for both deposit and withdrawal actions.

5. **Access Control**:
   - Only the contract owner can modify the minimum investment requirement.

6. **Supports Interface for Multiple Standards**:
   - Supports ERC4626 and other standards necessary for interoperability.

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
     const minInvestment = ethers.utils.parseUnits("1000", 18); // Minimum investment

     // Deploy the contract
     const RealAssetVaultContract = await ethers.getContractFactory("RealAssetVaultContract");
     const vaultContract = await RealAssetVaultContract.deploy(vaultTokenAddress, minInvestment);

     console.log("Real Asset Vault Contract deployed to:", vaultContract.address);
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
   - Write unit tests for vault functionalities like deposits, withdrawals, and share conversions.
   - Conduct security audits to ensure safe handling of pooled assets.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

This contract is structured to manage pooled real assets in a secure, efficient, and modular way. Adjust parameters like minimum investment as needed, and consider additional functionalities like staking or yield farming based on your use case.