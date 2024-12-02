Here's the smart contract for the **Restricted ETF Token Contract** using the ERC1404 standard. This contract ensures that only authorized investors can trade or hold ETF tokens by enforcing restricted transfers.

### Contract: 2-1Z_2A_RestrictedETFToken.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract RestrictedETFToken is IERC1404, Ownable {
    // Token details
    string public name = "Restricted ETF Token";
    string public symbol = "RETF";
    uint8 public decimals = 18;

    // Total supply
    uint256 private totalSupply_;

    // Mappings for balance and allowed transfers
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    // Whitelist and blacklist mappings
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    // Events
    event AddressWhitelisted(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);

    // ERC1404 compliance reasons
    string constant NOT_WHITELISTED = "Sender not whitelisted";
    string constant BLACKLISTED = "Sender is blacklisted";

    constructor(uint256 initialSupply) {
        totalSupply_ = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
    }

    // Function to transfer tokens
    function transfer(address to, uint256 value) external returns (bool) {
        require(isTransferAllowed(msg.sender, to), "Transfer not allowed");
        _transfer(msg.sender, to, value);
        return true;
    }

    // Internal transfer function
    function _transfer(address from, address to, uint256 value) internal {
        require(balances[from] >= value, "Insufficient balance");
        balances[from] -= value;
        balances[to] += value;
    }

    // Check if the transfer is allowed
    function isTransferAllowed(address from, address to) internal view returns (bool) {
        if (blacklist[from] || blacklist[to]) return false;
        return whitelist[from] && whitelist[to];
    }

    // Owner-only function to whitelist an address
    function addToWhitelist(address account) external onlyOwner {
        require(!whitelist[account], "Already whitelisted");
        whitelist[account] = true;
        emit AddressWhitelisted(account);
    }

    // Owner-only function to remove an address from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelist[account], "Not whitelisted");
        whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    // Owner-only function to blacklist an address
    function addToBlacklist(address account) external onlyOwner {
        require(!blacklist[account], "Already blacklisted");
        blacklist[account] = true;
        emit AddressBlacklisted(account);
    }

    // Owner-only function to remove an address from the blacklist
    function removeFromBlacklist(address account) external onlyOwner {
        require(blacklist[account], "Not blacklisted");
        blacklist[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }

    // Function to check the total supply
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    // Function to check the balance of an address
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // ERC1404 compliance methods
    function detectTransferRestriction(address from, address to) external view returns (uint8) {
        if (blacklist[from] || blacklist[to]) {
            return 1; // Blacklisted
        } else if (!whitelist[from] || !whitelist[to]) {
            return 2; // Not whitelisted
        }
        return 0; // No restriction
    }

    function canTransfer(address from, address to) external view returns (bool) {
        return isTransferAllowed(from, to);
    }
}
```

### Contract Explanation:

1. **Token Properties:**
   - Sets token name, symbol, and total supply.

2. **Whitelist and Blacklist Management:**
   - Manages mappings for whitelisted and blacklisted addresses.
   - Only the owner can add or remove addresses from these lists.

3. **Transfer Restrictions:**
   - Implements logic to restrict token transfers based on whitelist and blacklist status.
   - Provides methods to check transfer restrictions and balances.

4. **Events:**
   - Emits events when addresses are added or removed from the whitelist or blacklist.

5. **ERC1404 Compliance:**
   - Implements functions to check transfer restrictions and ensure compliance with the ERC1404 standard.

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
     const initialSupply = 1000000; // Set initial supply as needed
     const RestrictedETFToken = await hre.ethers.getContractFactory("RestrictedETFToken");
     const restrictedETFToken = await RestrictedETFToken.deploy(initialSupply);
     await restrictedETFToken.deployed();
     console.log("Restricted ETF Token Contract deployed to:", restrictedETFToken.address);
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
   Use Mocha and Chai for testing core functionalities like whitelisting and transferring tokens.

   ```javascript
   const { expect } = require("chai");

   describe("RestrictedETFToken", function () {
     let restrictedETFToken;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const RestrictedETFToken = await ethers.getContractFactory("RestrictedETFToken");
       restrictedETFToken = await RestrictedETFToken.deploy(1000000);
       await restrictedETFToken.deployed();
     });

     it("Should allow the owner to whitelist an address", async function () {
       await restrictedETFToken.addToWhitelist(investor.address);
       expect(await restrictedETFToken.whitelist(investor.address)).to.be.true;
     });

     it("Should not allow transfers from a non-whitelisted address", async function () {
       await expect(restrictedETFToken.transfer(investor.address, 100)).to.be.revertedWith("Sender not whitelisted");
     });

     it("Should allow transfers from a whitelisted address", async function () {
       await restrictedETFToken.addToWhitelist(investor.address);
       await restrictedETFToken.transfer(investor.address, 100);
       expect(await restrictedETFToken.balanceOf(investor.address)).to.equal(100);
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
   - Provide clear instructions on managing the whitelist and blacklist.

3. **Developer Guide:**
   - Explain the contract's architecture, focusing on compliance and transfer restrictions.

This contract provides a robust mechanism for ensuring compliance in trading ETF tokens by enforcing restricted transfers. If you have further modifications or specific requirements, let me know!