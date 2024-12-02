Here’s the smart contract for the **Whitelisting/Blacklisting Contract for ETFs** using the ERC1400 standard. This contract ensures that only authorized investors can trade or hold ETF tokens by maintaining a whitelist of approved addresses and blacklisting unauthorized entities.

### Contract: 2-1Z_1F_WhitelistingBlacklisting.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract WhitelistingBlacklistingETF is Ownable {
    IERC1400 public securityToken;

    // Mapping for whitelisted addresses
    mapping(address => bool) public whitelist;
    // Mapping for blacklisted addresses
    mapping(address => bool) public blacklist;

    event AddressWhitelisted(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);

    constructor(address _securityToken) {
        securityToken = IERC1400(_securityToken);
    }

    // Function to add an address to the whitelist
    function addToWhitelist(address account) external onlyOwner {
        require(!whitelist[account], "Address already whitelisted");
        whitelist[account] = true;
        emit AddressWhitelisted(account);
    }

    // Function to remove an address from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelist[account], "Address not whitelisted");
        whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    // Function to add an address to the blacklist
    function addToBlacklist(address account) external onlyOwner {
        require(!blacklist[account], "Address already blacklisted");
        blacklist[account] = true;
        emit AddressBlacklisted(account);
    }

    // Function to remove an address from the blacklist
    function removeFromBlacklist(address account) external onlyOwner {
        require(blacklist[account], "Address not blacklisted");
        blacklist[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }

    // Function to check if an address is whitelisted
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }

    // Function to check if an address is blacklisted
    function isBlacklisted(address account) external view returns (bool) {
        return blacklist[account];
    }

    // Override transfer functions to check whitelist/blacklist status
    function canTransfer(address from, address to) internal view {
        require(whitelist[from], "Sender not whitelisted");
        require(!blacklist[from], "Sender is blacklisted");
        require(whitelist[to], "Recipient not whitelisted");
        require(!blacklist[to], "Recipient is blacklisted");
    }
}
```

### Contract Explanation:

1. **Whitelist and Blacklist Management:**
   - Maintains mappings for whitelisted and blacklisted addresses.
   - Only the contract owner can add or remove addresses from these lists.

2. **Events:**
   - Emits events for adding or removing addresses from the whitelist and blacklist for better tracking.

3. **Access Control:**
   - Ensures that only authorized addresses can hold or trade ETF tokens.

4. **Transfer Check:**
   - Includes a `canTransfer` function (to be integrated with your existing ERC1400 token transfer logic) that validates transfer conditions based on whitelist and blacklist status.

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
     const SecurityTokenAddress = "0x..."; // Replace with your deployed ERC1400 token address
     const WhitelistingBlacklistingETF = await hre.ethers.getContractFactory("WhitelistingBlacklistingETF");
     const whitelistingBlacklistingContract = await WhitelistingBlacklistingETF.deploy(SecurityTokenAddress);
     await whitelistingBlacklistingContract.deployed();
     console.log("Whitelisting/Blacklisting Contract deployed to:", whitelistingBlacklistingContract.address);
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
   Use Mocha and Chai for testing core functions like whitelisting and blacklisting.

   ```javascript
   const { expect } = require("chai");

   describe("WhitelistingBlacklistingETF", function () {
     let whitelistingContract;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const SecurityTokenMock = await ethers.getContractFactory("SecurityTokenMock");
       const securityToken = await SecurityTokenMock.deploy();
       await securityToken.deployed();

       const WhitelistingBlacklistingETF = await ethers.getContractFactory("WhitelistingBlacklistingETF");
       whitelistingContract = await WhitelistingBlacklistingETF.deploy(securityToken.address);
       await whitelistingContract.deployed();
     });

     it("Should allow the owner to whitelist an address", async function () {
       await whitelistingContract.addToWhitelist(investor.address);
       expect(await whitelistingContract.isWhitelisted(investor.address)).to.be.true;
     });

     it("Should allow the owner to blacklist an address", async function () {
       await whitelistingContract.addToBlacklist(investor.address);
       expect(await whitelistingContract.isBlacklisted(investor.address)).to.be.true;
     });

     it("Should not allow a non-owner to add to whitelist", async function () {
       await expect(whitelistingContract.connect(investor).addToWhitelist(investor.address)).to.be.revertedWith("Ownable: caller is not the owner");
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
   - Provide step-by-step instructions on how to manage the whitelist and blacklist.

3. **Developer Guide:**
   - Explain the contract architecture, focusing on whitelisting and blacklisting.

This contract provides a robust mechanism to ensure compliance in trading ETF tokens by managing a whitelist and blacklist of addresses. If you have further modifications or specific requirements, let me know!