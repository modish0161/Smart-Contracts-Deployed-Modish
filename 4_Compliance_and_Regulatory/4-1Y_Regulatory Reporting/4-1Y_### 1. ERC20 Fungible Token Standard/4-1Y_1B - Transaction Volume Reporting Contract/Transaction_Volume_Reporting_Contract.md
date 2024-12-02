### Solidity Smart Contract: 4-1Y_1B_Transaction_Volume_Reporting_Contract.sol

This smart contract tracks the volume of ERC20 token transactions across a token ecosystem and reports this data to regulatory authorities. It is specifically designed to monitor transaction volumes and ensure compliance with regulatory requirements such as anti-money laundering thresholds.

#### **Solidity Code: 4-1Y_1B_Transaction_Volume_Reporting_Contract.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TransactionVolumeReporting is ERC20, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant REPORTING_ROLE = keccak256("REPORTING_ROLE");

    struct TransactionVolume {
        address account;
        uint256 totalVolume;
    }

    mapping(address => uint256) private _transactionVolume;
    address[] private _reportedAddresses;

    event VolumeReported(address indexed reporter, uint256 timestamp, uint256 totalVolume);
    event TransactionTracked(address indexed from, address indexed to, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REPORTING_ROLE, msg.sender);
    }

    /**
     * @notice Override the transfer function to track transaction volumes.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        super._transfer(sender, recipient, amount);
        _trackTransactionVolume(sender, amount);
        _trackTransactionVolume(recipient, amount);
        emit TransactionTracked(sender, recipient, amount);
    }

    /**
     * @notice Tracks the transaction volume for a given address.
     * @param account The address to track volume for.
     * @param amount The transaction amount to add to the volume.
     */
    function _trackTransactionVolume(address account, uint256 amount) internal {
        if (_transactionVolume[account] == 0) {
            _reportedAddresses.push(account);
        }
        _transactionVolume[account] += amount;
    }

    /**
     * @notice Allows regulatory authorities to report transaction volumes.
     * @return TransactionVolume[] Array of all recorded transaction volumes.
     */
    function generateVolumeReport() external onlyRole(REPORTING_ROLE) nonReentrant returns (TransactionVolume[] memory) {
        uint256 length = _reportedAddresses.length;
        TransactionVolume[] memory volumes = new TransactionVolume[](length);

        for (uint256 i = 0; i < length; i++) {
            address account = _reportedAddresses[i];
            volumes[i] = TransactionVolume({
                account: account,
                totalVolume: _transactionVolume[account]
            });
        }
        
        emit VolumeReported(msg.sender, block.timestamp, length);
        return volumes;
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
     * @notice Grants reporting role to a new address.
     * @param account The address to grant the role to.
     */
    function grantReportingRole(address account) external onlyOwner {
        grantRole(REPORTING_ROLE, account);
    }

    /**
     * @notice Revokes reporting role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeReportingRole(address account) external onlyOwner {
        revokeRole(REPORTING_ROLE, account);
    }
}
```

### **Key Features of the Contract:**

1. **ERC20 Token Standard:**
   - Implements the ERC20 standard, allowing for the creation and management of fungible tokens.

2. **Transaction Volume Tracking:**
   - Overrides the `_transfer` function to track the transaction volume for each address involved in a transfer. The total volume of transactions is recorded in a mapping (`_transactionVolume`).

3. **Volume Reporting:**
   - Authorized users with the `REPORTING_ROLE` can generate a volume report of all transactions, providing the total volume for each address. This functionality supports regulatory reporting.

4. **Access Control:**
   - Utilizes `AccessControl` from OpenZeppelin to manage roles and permissions, enabling the contract owner to grant or revoke reporting privileges.

5. **Pausing Mechanism:**
   - The contract owner can pause all token transfers using OpenZeppelin’s `Pausable` module in case of emergencies or regulatory requirements.

6. **Events:**
   - Emits `VolumeReported` when a volume report is generated.
   - Emits `TransactionTracked` whenever a token transfer occurs, tracking the volume of transactions.

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

    const name = "VolumeToken";
    const symbol = "VOL";
    const TransactionVolumeReporting = await hre.ethers.getContractFactory("TransactionVolumeReporting");
    const contract = await TransactionVolumeReporting.deploy(name, symbol);

    await contract.deployed();
    console.log("TransactionVolumeReporting deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});
```

3. **Deployment Steps:**
   - Save the contract as `4-1Y_1B_Transaction_Volume_Reporting_Contract.sol` in the `contracts` directory.
   - Save the deployment script as `deploy.js` in the `scripts` directory.
   - Deploy the contract using:
     ```bash
     npx hardhat run scripts/deploy.js --network [network_name]
     ```

### **Test Suite (tests/TransactionVolumeReporting.test.js):**

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TransactionVolumeReporting", function () {
    let TransactionVolumeReporting, contract, owner, reporter, user1, user2;

    beforeEach(async function () {
        [owner, reporter, user1, user2] = await ethers.getSigners();

        const TransactionVolumeReporting = await ethers.getContractFactory("TransactionVolumeReporting");
        contract = await TransactionVolumeReporting.deploy("VolumeToken", "VOL");
        await contract.deployed();

        // Grant reporting role to reporter
        await contract.grantReportingRole(reporter.address);
    });

    it("Should track transaction volumes correctly", async function () {
        await contract.mint(user1.address, 1000);
        await contract.connect(user1).transfer(user2.address, 500);

        const volumeReport = await contract.connect(reporter).generateVolumeReport();
        expect(volumeReport.length).to.equal(2);
        expect(volumeReport[0].totalVolume).to.equal(500); // user1 total volume
        expect(volumeReport[1].totalVolume).to.equal(500); // user2 total volume
    });

    it("Should allow regulator to generate volume report", async function () {
        await contract.mint(user1.address, 1000);
        await contract.connect(user1).transfer(user2.address, 500);
        await contract.connect(user1).transfer(owner.address, 200);

        const volumeReport = await contract.connect(reporter).generateVolumeReport();
        expect(volumeReport.length).to.equal(3);
    });

    it("Should not allow non-reporters to generate volume report", async function () {
        await expect(contract.connect(user1).generateVolumeReport()).to.be.revertedWith(
            "AccessControl: account [address] is missing role [role]"
        );
    });

    it("Should allow owner to grant and revoke reporting role", async function () {
        await contract.revokeReportingRole(reporter.address);
        await expect(contract.connect(reporter).generateVolumeReport()).to.be.revertedWith(
            "AccessControl: account [address] is missing role [role]"
        );

        await contract.grantReportingRole(reporter.address);
        const volumeReport = await contract.connect(reporter).generateVolumeReport();
        expect(volumeReport.length).to.equal(0); // Report should be empty initially
    });

    it("Should allow owner to pause and unpause the contract", async function () {
        await contract.pause();
        await expect(contract.connect(user1).transfer(user2.address, 100)).to.be.revertedWith(
            "Pausable: paused"
        );

        await contract.unpause();
        await contract.connect(user1).transfer(user2.address, 100);
        const volumeReport = await contract.connect(reporter).generateVolumeReport();
        expect(volumeReport.length).to.equal(2);
    });
});
```

### **API Documentation:**

- **Functions:**
  - `generateVolumeReport()`: Allows reporting authorities to generate a volume report of all recorded transactions.
  - `grantReportingRole(address account)`: Grants the reporting role to a new address.
  - `revokeReportingRole(address account)`: Revokes the reporting role from an address.
  - `pause()`: Pauses the contract, stopping all transfers.
 

 - `unpause()`: Unpauses the contract, allowing transfers.
  - `mint(address account, uint256 amount)`: Mints new tokens (only for testing purposes).

This smart contract automates the reporting of transaction volumes for ERC20 token transactions, ensuring compliance with regulatory requirements. It enables authorized reporters to view and generate reports on token volumes and allows for role-based access control to manage compliance effectively.