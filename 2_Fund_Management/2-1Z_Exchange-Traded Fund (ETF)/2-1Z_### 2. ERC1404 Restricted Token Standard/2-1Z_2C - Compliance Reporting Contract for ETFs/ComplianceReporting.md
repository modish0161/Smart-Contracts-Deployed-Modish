Here's the smart contract for the **Compliance Reporting Contract for ETFs** using the ERC1404 standard. This contract automatically generates reports for regulatory bodies, ensuring that all ETF token transactions comply with applicable financial regulations.

### Contract: 2-1Z_2C_ComplianceReporting.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract ComplianceReporting is IERC1404, Ownable {
    // Token details
    string public name = "Compliance Reporting ETF Token";
    string public symbol = "CRET";
    uint8 public decimals = 18;

    // Total supply
    uint256 private totalSupply_;

    // Mappings for balance and allowed transfers
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    // Transaction records for compliance reporting
    struct Transaction {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
    }

    Transaction[] public transactionRecords;

    // Accreditation mappings
    mapping(address => bool) public accredited;
    mapping(address => bool) public blacklist;

    // Events
    event TransactionLogged(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

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

        // Log transaction for compliance reporting
        logTransaction(from, to, value);
    }

    // Check if the transfer is allowed
    function isTransferAllowed(address from, address to) internal view returns (bool) {
        if (blacklist[from] || blacklist[to]) return false;
        return accredited[from] && accredited[to];
    }

    // Log transaction details for compliance reporting
    function logTransaction(address from, address to, uint256 amount) internal {
        transactionRecords.push(Transaction({
            from: from,
            to: to,
            amount: amount,
            timestamp: block.timestamp
        }));
        emit TransactionLogged(from, to, amount, block.timestamp);
    }

    // Function to retrieve transaction records
    function getTransactionRecords() external view returns (Transaction[] memory) {
        return transactionRecords;
    }

    // Owner-only function to accredit an address
    function accreditAddress(address account) external onlyOwner {
        require(!accredited[account], "Already accredited");
        accredited[account] = true;
    }

    // Owner-only function to remove accreditation from an address
    function removeAccreditation(address account) external onlyOwner {
        require(accredited[account], "Not accredited");
        accredited[account] = false;
    }

    // Owner-only function to blacklist an address
    function addToBlacklist(address account) external onlyOwner {
        require(!blacklist[account], "Already blacklisted");
        blacklist[account] = true;
    }

    // Owner-only function to remove an address from the blacklist
    function removeFromBlacklist(address account) external onlyOwner {
        require(blacklist[account], "Not blacklisted");
        blacklist[account] = false;
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

2. **Transaction Logging:**
   - Records all token transactions to maintain compliance reporting for regulatory bodies.

3. **Accreditation Management:**
   - Manages mappings for accredited and blacklisted addresses.
   - Only the owner can accredit or blacklist addresses.

4. **Transfer Restrictions:**
   - Implements logic to restrict token transfers based on accreditation status.
   - Provides methods to check transfer restrictions and balances.

5. **Events:**
   - Emits events for transactions logged, ensuring transparency.

6. **ERC1404 Compliance:**
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
     const ComplianceReporting = await hre.ethers.getContractFactory("ComplianceReporting");
     const complianceReporting = await ComplianceReporting.deploy(initialSupply);
     await complianceReporting.deployed();
     console.log("Compliance Reporting Contract deployed to:", complianceReporting.address);
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
   Use Mocha and Chai for testing core functionalities like logging transactions and managing accreditation.

   ```javascript
   const { expect } = require("chai");

   describe("ComplianceReporting", function () {
     let complianceReporting;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const ComplianceReporting = await ethers.getContractFactory("ComplianceReporting");
       complianceReporting = await ComplianceReporting.deploy(1000000);
       await complianceReporting.deployed();
     });

     it("Should allow the owner to accredit an address", async function () {
       await complianceReporting.accreditAddress(investor.address);
       expect(await complianceReporting.accredited(investor.address)).to.be.true;
     });

     it("Should not allow transfers from a non-accredited address", async function () {
       await expect(complianceReporting.transfer(investor.address, 100)).to.be.revertedWith("Sender not accredited");
     });

     it("Should log transactions for accredited transfers", async function () {
       await complianceReporting.accreditAddress(investor.address);
       await complianceReporting.transfer(investor.address, 100);
       const records = await complianceReporting.getTransactionRecords();
       expect(records.length).to.equal(1);
       expect(records[0].from).to.equal(owner.address);
       expect(records[0].to).to.equal(investor.address);
       expect(records[0].amount).to.equal(100);
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
   - Provide clear instructions on managing accreditations and viewing transaction reports.

3. **Developer Guide:**
   - Explain the contract's architecture, focusing on compliance reporting and transfer restrictions.

This contract facilitates compliance reporting for ETF transactions, ensuring adherence to regulations while maintaining transparency. If you have any additional requirements or need further adjustments, just let me know!