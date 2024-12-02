### Solidity Smart Contract: 4-1Y_1A_Basic_Regulatory_Reporting_Contract.sol

This smart contract enables automated regulatory reporting of ERC20 token transactions, ensuring compliance with regulatory requirements for token-based ecosystems. It collects transaction data and allows authorized parties to submit reports periodically to regulatory authorities.

#### **Solidity Code: 4-1Y_1A_Basic_Regulatory_Reporting_Contract.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BasicRegulatoryReporting is ERC20, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant REGULATORY_ROLE = keccak256("REGULATORY_ROLE");

    struct TransactionRecord {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
    }

    TransactionRecord[] private transactions;

    event TransactionRecorded(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event ReportGenerated(address indexed regulator, uint256 reportId, uint256 timestamp);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REGULATORY_ROLE, msg.sender);
    }

    /**
     * @notice Override the transfer function to record transactions for regulatory reporting.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        super._transfer(sender, recipient, amount);
        _recordTransaction(sender, recipient, amount);
    }

    /**
     * @notice Records each token transfer transaction.
     * @param from The address sending tokens.
     * @param to The address receiving tokens.
     * @param amount The number of tokens transferred.
     */
    function _recordTransaction(address from, address to, uint256 amount) internal {
        transactions.push(TransactionRecord({
            from: from,
            to: to,
            amount: amount,
            timestamp: block.timestamp
        }));
        emit TransactionRecorded(from, to, amount, block.timestamp);
    }

    /**
     * @notice Allows regulatory authorities to generate and view a report of all recorded transactions.
     * @return TransactionRecord[] Array of all recorded transactions.
     */
    function generateReport() external onlyRole(REGULATORY_ROLE) nonReentrant returns (TransactionRecord[] memory) {
        emit ReportGenerated(msg.sender, transactions.length, block.timestamp);
        return transactions;
    }

    /**
     * @notice Pauses all token transfers. Can only be called by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers. Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Grants regulatory role to a new address.
     * @param account The address to grant the role to.
     */
    function grantRegulatoryRole(address account) external onlyOwner {
        grantRole(REGULATORY_ROLE, account);
    }

    /**
     * @notice Revokes regulatory role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeRegulatoryRole(address account) external onlyOwner {
        revokeRole(REGULATORY_ROLE, account);
    }
}
```

### **Key Features of the Contract:**

1. **ERC20 Token Standard:**
   - The contract implements the ERC20 standard for fungible tokens, allowing for basic token functionalities such as `transfer`, `approve`, and `transferFrom`.

2. **Transaction Recording:**
   - Overrides the `_transfer` function to record each transaction, storing details such as sender, receiver, amount, and timestamp.

3. **Regulatory Role:**
   - Introduces a `REGULATORY_ROLE` that allows designated authorities to generate and view reports of all recorded transactions.

4. **Access Control:**
   - Uses `AccessControl` from OpenZeppelin to manage roles and permissions, with `DEFAULT_ADMIN_ROLE` and `REGULATORY_ROLE`.

5. **Pausing Mechanism:**
   - Enables the contract owner to pause all token transfers in case of emergencies, using OpenZeppelin’s `Pausable` module.

6. **Report Generation:**
   - Allows authorized users (regulatory authorities) to generate reports of all transactions. The report consists of an array of all recorded transactions.

### **Deployment Instructions:**

1. **Prerequisites:**
   - Install Node.js, Hardhat, and OpenZeppelin Contracts:
     ```bash
     npm install @openzeppelin/contracts @nomiclabs/hardhat-ethers ethers
     ```

2. **Deployment Script (deploy.js):**

```javascript
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const name = "RegulatoryToken";
    const symbol = "REG";
    const BasicRegulatoryReporting = await hre.ethers.getContractFactory("BasicRegulatoryReporting");
    const contract = await BasicRegulatoryReporting.deploy(name, symbol);

    await contract.deployed();
    console.log("BasicRegulatoryReporting deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});
```

3. **Deployment Steps:**
   - Save the contract as `4-1Y_1A_Basic_Regulatory_Reporting_Contract.sol` in the `contracts` directory.
   - Save the deployment script as `deploy.js` in the `scripts` directory.
   - Deploy the contract using:
     ```bash
     npx hardhat run scripts/deploy.js --network [network_name]
     ```

### **Test Suite (tests/BasicRegulatoryReporting.test.js):**

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BasicRegulatoryReporting", function () {
    let BasicRegulatoryReporting, contract, owner, regulator, user1, user2;

    beforeEach(async function () {
        [owner, regulator, user1, user2] = await ethers.getSigners();

        const BasicRegulatoryReporting = await ethers.getContractFactory("BasicRegulatoryReporting");
        contract = await BasicRegulatoryReporting.deploy("RegulatoryToken", "REG");
        await contract.deployed();

        // Grant regulatory role to regulator
        await contract.grantRegulatoryRole(regulator.address);
    });

    it("Should allow transfers and record them", async function () {
        await contract.mint(user1.address, 1000);
        await contract.connect(user1).transfer(user2.address, 500);

        const transaction = await contract.connect(regulator).generateReport();
        expect(transaction.length).to.equal(1);
        expect(transaction[0].from).to.equal(user1.address);
        expect(transaction[0].to).to.equal(user2.address);
        expect(transaction[0].amount).to.equal(500);
    });

    it("Should allow regulator to generate report", async function () {
        await contract.mint(user1.address, 1000);
        await contract.connect(user1).transfer(user2.address, 500);
        await contract.connect(user1).transfer(owner.address, 200);

        const report = await contract.connect(regulator).generateReport();
        expect(report.length).to.equal(2);
    });

    it("Should not allow non-regulators to generate report", async function () {
        await expect(contract.connect(user1).generateReport()).to.be.revertedWith(
            "AccessControl: account [address] is missing role [role]"
        );
    });

    it("Should allow owner to grant and revoke regulatory role", async function () {
        await contract.revokeRegulatoryRole(regulator.address);
        await expect(contract.connect(regulator).generateReport()).to.be.revertedWith(
            "AccessControl: account [address] is missing role [role]"
        );

        await contract.grantRegulatoryRole(regulator.address);
        const report = await contract.connect(regulator).generateReport();
        expect(report.length).to.equal(0); // Report should be empty
    });

    it("Should allow owner to pause and unpause the contract", async function () {
        await contract.pause();
        await expect(contract.connect(user1).transfer(user2.address, 100)).to.be.revertedWith(
            "Pausable: paused"
        );

        await contract.unpause();
        await contract.connect(user1).transfer(user2.address, 100);
        const report = await contract.connect(regulator).generateReport();
        expect(report.length).to.equal(1);
    });
});
```

### **API Documentation:**

- **Functions:**
  - `generateReport()`: Allows regulatory authorities to generate a report of all recorded transactions.
  - `grantRegulatoryRole(address account)`: Grants the regulatory role to a new address.
  - `revokeRegulatoryRole(address account)`: Revokes the regulatory role from an address.
  - `pause()`: Pauses the contract, stopping all transfers.
  - `unpause()`: Unpauses the contract, allowing transfers.
  - `mint(address account, uint256 amount)`: Mints new tokens (only for testing purposes).

This smart contract automates regulatory reporting of ERC20 token transactions while ensuring compliance with regulatory requirements. It enables authorized regulators to view and generate reports on token transfers and allows for role-based access control to manage compliance effectively.