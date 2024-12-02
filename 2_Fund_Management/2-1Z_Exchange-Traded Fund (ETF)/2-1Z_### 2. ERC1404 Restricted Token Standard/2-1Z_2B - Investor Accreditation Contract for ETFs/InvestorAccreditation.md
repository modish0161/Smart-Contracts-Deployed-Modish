Here's the smart contract for the **Investor Accreditation Contract for ETFs** using the ERC1404 standard. This contract verifies the accreditation status of ETF token holders, ensuring only qualified investors can buy, sell, or hold ETF tokens.

### Contract: 2-1Z_2B_InvestorAccreditation.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract InvestorAccreditation is IERC1404, Ownable {
    // Token details
    string public name = "Investor Accredited ETF Token";
    string public symbol = "IAETF";
    uint8 public decimals = 18;

    // Total supply
    uint256 private totalSupply_;

    // Mappings for balance and allowed transfers
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    // Accreditation mappings
    mapping(address => bool) public accredited;
    mapping(address => bool) public blacklist;

    // Events
    event AddressAccredited(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRemovedFromAccreditation(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);

    // ERC1404 compliance reasons
    string constant NOT_ACCREDITED = "Sender not accredited";
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
        return accredited[from] && accredited[to];
    }

    // Owner-only function to accredit an address
    function accreditAddress(address account) external onlyOwner {
        require(!accredited[account], "Already accredited");
        accredited[account] = true;
        emit AddressAccredited(account);
    }

    // Owner-only function to remove accreditation from an address
    function removeAccreditation(address account) external onlyOwner {
        require(accredited[account], "Not accredited");
        accredited[account] = false;
        emit AddressRemovedFromAccreditation(account);
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
        } else if (!accredited[from] || !accredited[to]) {
            return 2; // Not accredited
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

2. **Accreditation Management:**
   - Manages mappings for accredited and blacklisted addresses.
   - Only the owner can accredit or blacklist addresses.

3. **Transfer Restrictions:**
   - Implements logic to restrict token transfers based on accreditation status.
   - Provides methods to check transfer restrictions and balances.

4. **Events:**
   - Emits events when addresses are accredited or removed from accreditation, and when they are blacklisted or removed from the blacklist.

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
     const InvestorAccreditation = await hre.ethers.getContractFactory("InvestorAccreditation");
     const investorAccreditation = await InvestorAccreditation.deploy(initialSupply);
     await investorAccreditation.deployed();
     console.log("Investor Accreditation Contract deployed to:", investorAccreditation.address);
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
   Use Mocha and Chai for testing core functionalities like accreditation and transferring tokens.

   ```javascript
   const { expect } = require("chai");

   describe("InvestorAccreditation", function () {
     let investorAccreditation;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const InvestorAccreditation = await ethers.getContractFactory("InvestorAccreditation");
       investorAccreditation = await InvestorAccreditation.deploy(1000000);
       await investorAccreditation.deployed();
     });

     it("Should allow the owner to accredit an address", async function () {
       await investorAccreditation.accreditAddress(investor.address);
       expect(await investorAccreditation.accredited(investor.address)).to.be.true;
     });

     it("Should not allow transfers from a non-accredited address", async function () {
       await expect(investorAccreditation.transfer(investor.address, 100)).to.be.revertedWith("Sender not accredited");
     });

     it("Should allow transfers from an accredited address", async function () {
       await investorAccreditation.accreditAddress(investor.address);
       await investorAccreditation.transfer(investor.address, 100);
       expect(await investorAccreditation.balanceOf(investor.address)).to.equal(100);
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
   - Provide clear instructions on managing accreditations and transfers.

3. **Developer Guide:**
   - Explain the contract's architecture, focusing on compliance and transfer restrictions.

This contract provides a robust mechanism for ensuring only accredited investors can hold and trade ETF tokens, adhering to regulatory requirements. If you need any further modifications or specific features, feel free to ask!