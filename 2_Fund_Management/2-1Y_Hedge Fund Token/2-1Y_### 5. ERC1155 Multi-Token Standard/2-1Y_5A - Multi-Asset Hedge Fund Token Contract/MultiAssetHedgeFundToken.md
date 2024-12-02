Here's a complete smart contract for the **Multi-Asset Hedge Fund Token Contract** using the ERC1155 standard. This contract enables the tokenization of multiple asset classes within a hedge fund, allowing investors to diversify their investments.

### Contract: 2-1Y_5A_MultiAssetHedgeFundToken.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MultiAssetHedgeFundToken is ERC1155, Ownable, ReentrancyGuard {
    // Mapping to track asset prices
    mapping(uint256 => uint256) public assetPrices; 
    mapping(uint256 => string) public assetNames; 
    mapping(uint256 => uint256) public totalSupply; 

    event AssetAdded(uint256 indexed id, string name, uint256 price);
    event AssetPriceUpdated(uint256 indexed id, uint256 newPrice);
    event TokensMinted(address indexed investor, uint256 indexed id, uint256 amount);
    event TokensBurned(address indexed investor, uint256 indexed id, uint256 amount);

    constructor() ERC1155("https://api.example.com/metadata/{id}.json") {}

    // Function to add a new asset
    function addAsset(uint256 id, string memory name, uint256 price) external onlyOwner {
        require(assetPrices[id] == 0, "Asset already exists");
        assetPrices[id] = price;
        assetNames[id] = name;
        emit AssetAdded(id, name, price);
    }

    // Function to update asset price
    function updateAssetPrice(uint256 id, uint256 newPrice) external onlyOwner {
        require(assetPrices[id] > 0, "Asset does not exist");
        assetPrices[id] = newPrice;
        emit AssetPriceUpdated(id, newPrice);
    }

    // Function to mint new tokens for a specific asset
    function mintTokens(uint256 id, uint256 amount) external nonReentrant {
        require(assetPrices[id] > 0, "Asset does not exist");
        _mint(msg.sender, id, amount, ""); // Mint tokens for the specified asset
        totalSupply[id] += amount;
        emit TokensMinted(msg.sender, id, amount);
    }

    // Function to burn tokens for a specific asset
    function burnTokens(uint256 id, uint256 amount) external nonReentrant {
        require(totalSupply[id] >= amount, "Not enough tokens to burn");
        _burn(msg.sender, id, amount); // Burn tokens for the specified asset
        totalSupply[id] -= amount;
        emit TokensBurned(msg.sender, id, amount);
    }

    // Function to get asset details
    function getAssetDetails(uint256 id) external view returns (string memory name, uint256 price, uint256 supply) {
        name = assetNames[id];
        price = assetPrices[id];
        supply = totalSupply[id];
    }
}
```

### Contract Explanation:

1. **ERC1155 Standard:**
   - This contract uses the ERC1155 multi-token standard, which allows for tokenizing multiple asset classes within a single contract.

2. **Asset Management:**
   - `addAsset`: Allows the owner to add a new asset with an associated name and price.
   - `updateAssetPrice`: Allows the owner to update the price of an existing asset.

3. **Token Minting and Burning:**
   - `mintTokens`: Allows investors to mint tokens for specific assets.
   - `burnTokens`: Allows investors to burn their tokens for specific assets.

4. **Events:**
   - Emits events for asset additions, price updates, token minting, and burning, enhancing transparency.

5. **Asset Details Retrieval:**
   - `getAssetDetails`: Provides a way to retrieve asset details, including name, price, and total supply.

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

     const MultiAssetHedgeFundToken = await hre.ethers.getContractFactory("MultiAssetHedgeFundToken");
     const token = await MultiAssetHedgeFundToken.deploy();

     await token.deployed();
     console.log("Multi-Asset Hedge Fund Token Contract deployed to:", token.address);
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
   Use Mocha and Chai for testing core functions such as asset addition, minting, and burning.

   ```javascript
   const { expect } = require("chai");

   describe("Multi-Asset Hedge Fund Token", function () {
     let contract;
     let owner, investor1;

     beforeEach(async function () {
       [owner, investor1] = await ethers.getSigners();

       const MultiAssetHedgeFundToken = await ethers.getContractFactory("MultiAssetHedgeFundToken");
       contract = await MultiAssetHedgeFundToken.deploy();
       await contract.deployed();
     });

     it("Should allow owner to add a new asset", async function () {
       await contract.addAsset(1, "Stock", 100);
       const details = await contract.getAssetDetails(1);
       expect(details.name).to.equal("Stock");
       expect(details.price).to.equal(100);
     });

     it("Should allow minting of tokens", async function () {
       await contract.addAsset(1, "Stock", 100);
       await contract.mintTokens(1, 10);
       const balance = await contract.balanceOf(investor1.address, 1);
       expect(balance).to.equal(10);
     });

     it("Should allow burning of tokens", async function () {
       await contract.addAsset(1, "Stock", 100);
       await contract.mintTokens(1, 10);
       await contract.burnTokens(1, 5);
       const balance = await contract.balanceOf(investor1.address, 1);
       expect(balance).to.equal(5);
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
   - Provide step-by-step instructions on how to manage assets and tokens.

3. **Developer Guide:**
   - Explain the contract architecture, including asset management and token operations.

This smart contract framework allows for efficient management of multiple asset classes within a hedge fund. If you need any modifications or additional features, just let me know!