Here’s a complete smart contract for the **Hedge Fund Vault Token Contract** using the ERC4626 standard. This contract enables the tokenization of a hedge fund as a vault, allowing for pooled assets managed by the fund.

### Contract: 2-1Y_6A_HedgeFundVaultToken.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HedgeFundVaultToken is ERC4626, Ownable, ReentrancyGuard {
    // Mapping for asset management
    mapping(address => uint256) public totalInvested;
    mapping(address => uint256) public totalWithdrawn;

    event Deposited(address indexed investor, uint256 amount);
    event Withdrawn(address indexed investor, uint256 amount);
    event SharesMinted(address indexed investor, uint256 shares);
    event SharesBurned(address indexed investor, uint256 shares);

    constructor(IERC20 asset) ERC4626(asset) {}

    // Deposit funds into the vault
    function deposit(uint256 assets, address to) public nonReentrant returns (uint256 shares) {
        shares = super.deposit(assets, to);
        totalInvested[to] += assets;

        emit Deposited(to, assets);
        emit SharesMinted(to, shares);
    }

    // Withdraw funds from the vault
    function withdraw(uint256 assets, address to, address from) public nonReentrant returns (uint256 shares) {
        shares = super.withdraw(assets, to, from);
        totalWithdrawn[from] += assets;

        emit Withdrawn(from, assets);
        emit SharesBurned(from, shares);
    }

    // Override the 'convertToShares' method to provide share calculations
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        shares = super.convertToShares(assets);
    }

    // Override the 'convertToAssets' method to provide asset calculations
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        assets = super.convertToAssets(shares);
    }

    // Get total investments made by an investor
    function getTotalInvested(address investor) public view returns (uint256) {
        return totalInvested[investor];
    }

    // Get total withdrawals made by an investor
    function getTotalWithdrawn(address investor) public view returns (uint256) {
        return totalWithdrawn[investor];
    }
}
```

### Contract Explanation:

1. **ERC4626 Standard:**
   - This contract uses the ERC4626 standard, enabling the pooling of assets and the representation of shares in a vault.

2. **Deposit and Withdrawal Functions:**
   - `deposit`: Allows investors to deposit assets into the vault, minting shares in return.
   - `withdraw`: Allows investors to withdraw assets, burning shares accordingly.

3. **Tracking Investments:**
   - Keeps track of total investments and withdrawals for each investor using mappings.

4. **Events:**
   - Emits events for deposits, withdrawals, shares minted, and shares burned for transparency.

5. **Share Calculations:**
   - Overrides the `convertToShares` and `convertToAssets` methods to handle share-to-asset conversions properly.

### Deployment Instructions:

1. **Prerequisites:**
   - Ensure you have Node.js and Hardhat installed.
   - Install OpenZeppelin contracts:
     ```bash
     npm install @openzeppelin/contracts
     ```

2. **Deployment Script:**
   Create a deployment script `deploy.js` in the `scripts` folder:

   ```javascript
   const hre = require("hardhat");

   async function main() {
     const [deployer] = await hre.ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const Asset = await hre.ethers.getContractFactory("YourERC20Token"); // Replace with your ERC20 token
     const asset = await Asset.deploy(/* constructor args */);
     await asset.deployed();

     const HedgeFundVaultToken = await hre.ethers.getContractFactory("HedgeFundVaultToken");
     const vaultToken = await HedgeFundVaultToken.deploy(asset.address);

     await vaultToken.deployed();
     console.log("Hedge Fund Vault Token Contract deployed to:", vaultToken.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

3. **Run the Deployment Script:**
   ```bash
   npx hardhat run scripts/deploy.js --network [network-name]
   ```

### Testing Suite:

1. **Basic Tests:**
   Use Mocha and Chai for testing core functions such as deposits and withdrawals.

   ```javascript
   const { expect } = require("chai");

   describe("Hedge Fund Vault Token", function () {
     let vault;
     let asset;
     let owner, investor1;

     beforeEach(async function () {
       [owner, investor1] = await ethers.getSigners();

       const Asset = await ethers.getContractFactory("YourERC20Token"); // Replace with your ERC20 token
       asset = await Asset.deploy(/* constructor args */);
       await asset.deployed();

       const HedgeFundVaultToken = await ethers.getContractFactory("HedgeFundVaultToken");
       vault = await HedgeFundVaultToken.deploy(asset.address);
       await vault.deployed();
     });

     it("Should allow deposits", async function () {
       await asset.mint(investor1.address, ethers.utils.parseEther("100"));
       await asset.connect(investor1).approve(vault.address, ethers.utils.parseEther("100"));
       await vault.connect(investor1).deposit(ethers.utils.parseEther("100"), investor1.address);

       const balance = await vault.balanceOf(investor1.address);
       expect(balance).to.be.gt(0);
     });

     it("Should allow withdrawals", async function () {
       await asset.mint(investor1.address, ethers.utils.parseEther("100"));
       await asset.connect(investor1).approve(vault.address, ethers.utils.parseEther("100"));
       await vault.connect(investor1).deposit(ethers.utils.parseEther("100"), investor1.address);
       await vault.connect(investor1).withdraw(ethers.utils.parseEther("100"), investor1.address, investor1.address);

       const balance = await vault.balanceOf(investor1.address);
       expect(balance).to.equal(0);
     });
   });
   ```

2. **Run Tests:**
   ```bash
   npx hardhat test
   ```

### Documentation:

1. **API Documentation:**
   - Include detailed NatSpec comments for each function, event, and modifier in the contract.

2. **User Guide:**
   - Provide step-by-step instructions on how to manage investments and tokens.

3. **Developer Guide:**
   - Explain the contract architecture, including asset management and token operations.

This contract framework provides a robust structure for a hedge fund vault, allowing for efficient management of pooled assets. If you need any modifications or additional features, feel free to ask!