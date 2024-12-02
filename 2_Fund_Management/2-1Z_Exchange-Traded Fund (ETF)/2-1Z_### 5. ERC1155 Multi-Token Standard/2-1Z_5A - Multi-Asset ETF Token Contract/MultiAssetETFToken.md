Here's the smart contract for the **Multi-Asset ETF Token Contract** using the ERC1155 standard. This contract allows for the tokenization of multiple asset types within a single ETF.

### Contract: 2-1Z_5A_MultiAssetETFToken.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MultiAssetETFToken is ERC1155, Ownable, Pausable {
    
    // Mapping to track the total supply of each asset type
    mapping(uint256 => uint256) private _totalSupply;

    event AssetCreated(uint256 indexed id, uint256 supply);
    event AssetMinted(address indexed account, uint256 indexed id, uint256 amount);
    event AssetBurned(address indexed account, uint256 indexed id, uint256 amount);
    
    constructor(string memory uri) ERC1155(uri) {}

    // Function to create a new asset type
    function createAsset(uint256 id, uint256 initialSupply) external onlyOwner {
        require(_totalSupply[id] == 0, "Asset already exists");
        _totalSupply[id] = initialSupply;
        _mint(msg.sender, id, initialSupply, "");
        emit AssetCreated(id, initialSupply);
    }

    // Function to mint new tokens for a specific asset type
    function mint(uint256 id, uint256 amount, bytes memory data) external onlyOwner whenNotPaused {
        require(_totalSupply[id] + amount >= _totalSupply[id], "Minting exceeds total supply limit");
        _totalSupply[id] += amount;
        _mint(msg.sender, id, amount, data);
        emit AssetMinted(msg.sender, id, amount);
    }

    // Function to burn tokens of a specific asset type
    function burn(uint256 id, uint256 amount) external whenNotPaused {
        require(balanceOf(msg.sender, id) >= amount, "Insufficient balance to burn");
        _burn(msg.sender, id, amount);
        _totalSupply[id] -= amount;
        emit AssetBurned(msg.sender, id, amount);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to get total supply of an asset
    function totalSupply(uint256 id) external view returns (uint256) {
        return _totalSupply[id];
    }

    // Override _beforeTokenTransfer to implement pausable functionality
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
```

### Contract Explanation:

1. **Token Properties:**
   - Inherits from OpenZeppelin's `ERC1155`, `Ownable`, and `Pausable`.

2. **Asset Management:**
   - The `createAsset` function allows the owner to create new asset types within the ETF.
   - The `mint` function allows the owner to mint new tokens for specific asset types.
   - The `burn` function enables holders to burn tokens of a specific asset type.

3. **Pausable Feature:**
   - Includes functionality to pause and unpause token transfers for security reasons.

4. **Total Supply Tracking:**
   - The contract keeps track of the total supply for each asset type.

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
     const MultiAssetETFToken = await hre.ethers.getContractFactory("MultiAssetETFToken");
     const multiAssetETFToken = await MultiAssetETFToken.deploy("https://api.example.com/metadata/{id}");
     await multiAssetETFToken.deployed();
     console.log("Multi-Asset ETF Token Contract deployed to:", multiAssetETFToken.address);
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
   Use Mocha and Chai for testing core functionalities such as asset creation, minting, and burning.

   ```javascript
   const { expect } = require("chai");

   describe("MultiAssetETFToken", function () {
     let multiAssetETFToken;
     let owner, addr1;

     beforeEach(async function () {
       [owner, addr1] = await ethers.getSigners();
       const MultiAssetETFToken = await ethers.getContractFactory("MultiAssetETFToken");
       multiAssetETFToken = await MultiAssetETFToken.deploy("https://api.example.com/metadata/{id}");
       await multiAssetETFToken.deployed();
     });

     it("Should allow the owner to create an asset", async function () {
       await multiAssetETFToken.createAsset(1, 1000);
       const totalSupply = await multiAssetETFToken.totalSupply(1);
       expect(totalSupply).to.equal(1000);
     });

     it("Should allow the owner to mint new tokens", async function () {
       await multiAssetETFToken.createAsset(1, 1000);
       await multiAssetETFToken.mint(1, 500, "0x");
       const totalSupply = await multiAssetETFToken.totalSupply(1);
       expect(totalSupply).to.equal(1500);
     });

     it("Should allow users to burn tokens", async function () {
       await multiAssetETFToken.createAsset(1, 1000);
       await multiAssetETFToken.mint(1, 500, "0x");
       await multiAssetETFToken.burn(1, 200);
       const totalSupply = await multiAssetETFToken.totalSupply(1);
       expect(totalSupply).to.equal(1300);
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
   - Provide clear instructions on how to create assets, mint, and burn tokens.

3. **Developer Guide:**
   - Explain the contract's architecture, focusing on the management of multiple asset types.

This contract facilitates the tokenization of a diversified ETF, allowing for flexible management of multiple asset classes. If you have further adjustments or additional features in mind, feel free to let me know!