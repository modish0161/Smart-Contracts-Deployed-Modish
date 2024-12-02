Here's the smart contract for the **Asset Bundling Contract for ETFs** using the ERC998 standard. This contract allows bundling multiple asset types or ETF tokens into a single composable token.

### Contract: 2-1Z_7B_AssetBundlingContract.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998.sol";

contract AssetBundlingContract is ERC998, Ownable {
    // Mapping from token ID to its assets
    mapping(uint256 => address[]) private _bundledAssets; // Array of asset contracts
    mapping(uint256 => uint256[]) private _assetIds;      // Array of asset IDs

    // Events
    event AssetsBundled(uint256 indexed tokenId, address[] assetContracts, uint256[] assetIds);
    event AssetsUnbundled(uint256 indexed tokenId, address[] assetContracts, uint256[] assetIds);

    constructor() ERC721("Asset Bundling Token", "ABT") {}

    // Create a new bundling token
    function createBundleToken() external onlyOwner returns (uint256) {
        uint256 tokenId = totalSupply(); // Use totalSupply to get a new token ID
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    // Bundle multiple assets into a single token
    function bundleAssets(uint256 tokenId, address[] memory assetContracts, uint256[] memory assetIds) external onlyOwner {
        require(assetContracts.length == assetIds.length, "Mismatched input lengths");
        
        for (uint256 i = 0; i < assetContracts.length; i++) {
            _bundledAssets[tokenId].push(assetContracts[i]);
            _assetIds[tokenId].push(assetIds[i]);
        }
        
        emit AssetsBundled(tokenId, assetContracts, assetIds);
    }

    // Unbundle assets from a token
    function unbundleAssets(uint256 tokenId) external onlyOwner {
        address[] memory assetContracts = _bundledAssets[tokenId];
        uint256[] memory assetIds = _assetIds[tokenId];

        delete _bundledAssets[tokenId];
        delete _assetIds[tokenId];

        emit AssetsUnbundled(tokenId, assetContracts, assetIds);
    }

    // Get the bundled assets for a token
    function getBundledAssets(uint256 tokenId) external view returns (address[] memory, uint256[] memory) {
        return (_bundledAssets[tokenId], _assetIds[tokenId]);
    }

    // Override required functions for ERC998
    function onERC721Received(address, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address from, uint256 id, uint256 value, bytes memory data) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
```

### Contract Explanation:

1. **Token Properties:**
   - Inherits from OpenZeppelin's `ERC721` and implements the `ERC998` composable interface.

2. **Core Functionality:**
   - **Token Creation:** The `createBundleToken` function allows the owner to mint new bundling tokens.
   - **Asset Bundling:** The `bundleAssets` function enables the owner to bundle multiple asset contracts and IDs into a single token.
   - **Asset Unbundling:** The `unbundleAssets` function allows the owner to unbundle all assets from a token.
   - **Asset Retrieval:** The `getBundledAssets` function returns the assets associated with a specific token.

3. **Event Emission:**
   - Events are emitted when assets are bundled or unbundled, providing transparency.

4. **Access Control:**
   - The contract uses `Ownable` to restrict asset management operations to the contract owner.

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
     const AssetBundlingContract = await hre.ethers.getContractFactory("AssetBundlingContract");
     const assetBundlingContract = await AssetBundlingContract.deploy();
     await assetBundlingContract.deployed();
     console.log("Asset Bundling Contract deployed to:", assetBundlingContract.address);
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
   Use Mocha and Chai for testing core functionalities such as token creation, asset bundling, and retrieval.

   ```javascript
   const { expect } = require("chai");

   describe("AssetBundlingContract", function () {
     let assetBundlingContract;
     let owner, addr1;

     beforeEach(async function () {
       [owner, addr1] = await ethers.getSigners();
       const AssetBundlingContract = await ethers.getContractFactory("AssetBundlingContract");
       assetBundlingContract = await AssetBundlingContract.deploy();
       await assetBundlingContract.deployed();
     });

     it("Should allow token creation", async function () {
       const tokenId = await assetBundlingContract.createBundleToken();
       expect(await assetBundlingContract.ownerOf(tokenId)).to.equal(owner.address);
     });

     it("Should allow assets to be bundled", async function () {
       const tokenId = await assetBundlingContract.createBundleToken();
       const assetContracts = [addr1.address];
       const assetIds = [1];
       await assetBundlingContract.bundleAssets(tokenId, assetContracts, assetIds);
       const assets = await assetBundlingContract.getBundledAssets(tokenId);
       expect(assets[0][0]).to.equal(addr1.address);
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
   - Provide clear instructions on how to create bundling tokens, bundle assets, and retrieve asset information.

3. **Developer Guide:**
   - Explain the contract's architecture, focusing on asset management and composable token features.

This contract provides a flexible way for investors to manage and trade diversified ETF holdings through a single composable token. If you have any further adjustments or specific functionalities in mind, feel free to ask!