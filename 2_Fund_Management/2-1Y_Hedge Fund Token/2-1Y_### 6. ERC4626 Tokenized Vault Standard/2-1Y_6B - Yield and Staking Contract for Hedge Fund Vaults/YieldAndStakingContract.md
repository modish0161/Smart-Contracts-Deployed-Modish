Here’s a complete smart contract for the **Yield and Staking Contract for Hedge Fund Vaults** using the ERC4626 standard. This contract allows hedge fund token holders to stake their tokens in the vault and earn yield based on the fund’s performance.

### Contract: 2-1Y_6B_YieldAndStakingContract.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YieldAndStakingContract is ERC4626, Ownable, ReentrancyGuard {
    // Mapping to store staking balances
    mapping(address => uint256) public stakedAmount;

    // Annual yield percentage (in basis points)
    uint256 public annualYieldBPS; // Basis Points for yield

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event YieldUpdated(uint256 newYield);

    constructor(IERC20 asset, uint256 initialYieldBPS) ERC4626(asset) {
        annualYieldBPS = initialYieldBPS;
    }

    // Stake tokens in the vault
    function stake(uint256 assets) public nonReentrant {
        require(assets > 0, "Cannot stake 0");
        
        // Transfer tokens to this contract
        asset().transferFrom(msg.sender, address(this), assets);
        
        // Mint shares for the user
        uint256 shares = deposit(assets, msg.sender);
        stakedAmount[msg.sender] += assets;

        emit Staked(msg.sender, assets);
    }

    // Unstake tokens from the vault
    function unstake(uint256 assets) public nonReentrant {
        require(stakedAmount[msg.sender] >= assets, "Insufficient staked amount");
        
        // Withdraw assets
        withdraw(assets, msg.sender, msg.sender);
        stakedAmount[msg.sender] -= assets;

        emit Unstaked(msg.sender, assets);
    }

    // Calculate yield for a user based on their staked amount
    function calculateYield(address user) public view returns (uint256) {
        return (stakedAmount[user] * annualYieldBPS) / 10000; // Yield in tokens
    }

    // Update the annual yield percentage
    function setAnnualYield(uint256 newYieldBPS) external onlyOwner {
        annualYieldBPS = newYieldBPS;
        emit YieldUpdated(newYieldBPS);
    }

    // Override the 'convertToShares' method for share calculations
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        shares = super.convertToShares(assets);
    }

    // Override the 'convertToAssets' method for asset calculations
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        assets = super.convertToAssets(shares);
    }
}
```

### Contract Explanation:

1. **ERC4626 Standard:**
   - This contract uses the ERC4626 standard, facilitating the pooling of assets and representation of shares in a vault.

2. **Staking Functionality:**
   - `stake`: Allows investors to stake their tokens, transferring assets to the contract and minting shares.
   - `unstake`: Allows investors to withdraw their staked tokens and burn shares accordingly.

3. **Yield Calculation:**
   - `calculateYield`: Computes yield based on the staked amount and the annual yield percentage.
   - `setAnnualYield`: Allows the owner to update the annual yield percentage.

4. **Events:**
   - Emits events for staking, unstaking, and yield updates to ensure transparency.

5. **Ownership and Control:**
   - The contract is owned by the deployer, allowing them to manage yield settings.

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

     const initialYieldBPS = 500; // Example yield of 5%
     const YieldAndStakingContract = await hre.ethers.getContractFactory("YieldAndStakingContract");
     const vaultContract = await YieldAndStakingContract.deploy(asset.address, initialYieldBPS);

     await vaultContract.deployed();
     console.log("Yield and Staking Contract deployed to:", vaultContract.address);
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
   Use Mocha and Chai for testing core functions such as staking and unstaking.

   ```javascript
   const { expect } = require("chai");

   describe("Yield and Staking Contract", function () {
     let vault;
     let asset;
     let owner, investor1;

     beforeEach(async function () {
       [owner, investor1] = await ethers.getSigners();

       const Asset = await ethers.getContractFactory("YourERC20Token"); // Replace with your ERC20 token
       asset = await Asset.deploy(/* constructor args */);
       await asset.deployed();

       const YieldAndStakingContract = await ethers.getContractFactory("YieldAndStakingContract");
       vault = await YieldAndStakingContract.deploy(asset.address, 500);
       await vault.deployed();
     });

     it("Should allow staking", async function () {
       await asset.mint(investor1.address, ethers.utils.parseEther("100"));
       await asset.connect(investor1).approve(vault.address, ethers.utils.parseEther("100"));
       await vault.connect(investor1).stake(ethers.utils.parseEther("100"));

       const stakedAmount = await vault.stakedAmount(investor1.address);
       expect(stakedAmount).to.equal(ethers.utils.parseEther("100"));
     });

     it("Should allow unstaking", async function () {
       await asset.mint(investor1.address, ethers.utils.parseEther("100"));
       await asset.connect(investor1).approve(vault.address, ethers.utils.parseEther("100"));
       await vault.connect(investor1).stake(ethers.utils.parseEther("100"));
       await vault.connect(investor1).unstake(ethers.utils.parseEther("100"));

       const stakedAmount = await vault.stakedAmount(investor1.address);
       expect(stakedAmount).to.equal(0);
     });

     it("Should calculate yield correctly", async function () {
       await asset.mint(investor1.address, ethers.utils.parseEther("100"));
       await asset.connect(investor1).approve(vault.address, ethers.utils.parseEther("100"));
       await vault.connect(investor1).stake(ethers.utils.parseEther("100"));

       const yieldAmount = await vault.calculateYield(investor1.address);
       expect(yieldAmount).to.equal(ethers.utils.parseEther("5")); // 5% of 100
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

This contract provides a solid foundation for a yield and staking mechanism within a hedge fund vault, allowing investors to earn additional income streams. If you need further modifications or additional features, let me know!