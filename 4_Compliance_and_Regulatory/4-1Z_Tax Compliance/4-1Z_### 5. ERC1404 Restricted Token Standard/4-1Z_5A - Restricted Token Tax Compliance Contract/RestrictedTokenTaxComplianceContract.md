### Solidity Smart Contract: 4-1Z_5A_RestrictedTokenTaxComplianceContract.sol

This smart contract is designed to manage tax compliance for restricted token transactions under the ERC1404 standard. It ensures that only compliant participants can hold or transfer tokens, and integrates tax calculation and reporting functionalities.

#### **Solidity Code: 4-1Z_5A_RestrictedTokenTaxComplianceContract.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RestrictedTokenTaxComplianceContract is ERC1404, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax calculations and transactions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Address of the tax authority to receive withheld taxes
    address public taxAuthority;

    // Tax rates for different transaction types
    struct TaxRate {
        uint256 transferTaxRate; // In basis points (e.g., 500 = 5%)
        uint256 dividendTaxRate; // In basis points (e.g., 1500 = 15%)
    }

    // Mapping to store tax rates for each token type (partition)
    mapping(bytes32 => TaxRate) public taxRates;

    // Events for tracking tax operations
    event TaxWithheld(address indexed holder, uint256 amount, uint256 taxAmount, bytes32 partition);
    event TaxRateUpdated(bytes32 indexed partition, uint256 transferTaxRate, uint256 dividendTaxRate, address updatedBy);
    event TaxAuthorityUpdated(address oldTaxAuthority, address newTaxAuthority);

    constructor(
        string memory name,
        string memory symbol,
        address[] memory controllers,
        address initialTaxAuthority
    ) ERC1404(name, symbol, controllers) {
        require(initialTaxAuthority != address(0), "Invalid tax authority address");

        taxAuthority = initialTaxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Modifier to check if caller is a compliance officer
    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), "Caller is not a compliance officer");
        _;
    }

    // Function to set tax rates for a token partition (only compliance officer)
    function setTaxRates(
        bytes32 partition,
        uint256 transferTaxRate,
        uint256 dividendTaxRate
    ) external onlyComplianceOfficer {
        require(transferTaxRate <= 10000 && dividendTaxRate <= 10000, "Tax rates should be <= 100%");
        taxRates[partition] = TaxRate(transferTaxRate, dividendTaxRate);
        emit TaxRateUpdated(partition, transferTaxRate, dividendTaxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Override transfer function to include tax withholding
    function _transferWithTax(
        bytes32 partition,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        uint256 taxAmount = (value * taxRates[partition].transferTaxRate) / 10000;
        uint256 netAmount = value - taxAmount;

        require(balanceOfByPartition(partition, from) >= value, "Insufficient balance");

        // Withhold tax and transfer to tax authority
        if (taxAmount > 0) {
            super._transferWithData(partition, from, taxAuthority, taxAmount, data);
            emit TaxWithheld(from, value, taxAmount, partition);
        }

        // Transfer net amount to recipient
        super._transferWithData(partition, from, to, netAmount, data);
    }

    // Override transfer function to ensure tax compliance
    function transferByPartition(
        bytes32 partition,
        address to,
        uint256 value,
        bytes memory data
    ) public override nonReentrant whenNotPaused returns (bytes32) {
        _transferWithTax(partition, msg.sender, to, value, data);
        return partition;
    }

    // Override redeem function to include tax withholding on dividends
    function redeemByPartition(
        bytes32 partition,
        uint256 value,
        bytes memory data
    ) public override nonReentrant whenNotPaused returns (bytes32) {
        uint256 taxAmount = (value * taxRates[partition].dividendTaxRate) / 10000;
        uint256 netAmount = value - taxAmount;

        require(balanceOfByPartition(partition, msg.sender) >= value, "Insufficient balance");

        // Withhold tax and transfer to tax authority
        if (taxAmount > 0) {
            super._transferWithData(partition, msg.sender, taxAuthority, taxAmount, data);
            emit TaxWithheld(msg.sender, value, taxAmount, partition);
        }

        // Redeem net amount
        return super.redeemByPartition(partition, netAmount, data);
    }

    // Function to pause the contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to add a compliance officer (only owner)
    function addComplianceOfficer(address officer) external onlyOwner {
        grantRole(COMPLIANCE_ROLE, officer);
    }

    // Function to remove a compliance officer (only owner)
    function removeComplianceOfficer(address officer) external onlyOwner {
        revokeRole(COMPLIANCE_ROLE, officer);
    }

    // Function to get tax rates for a partition
    function getTaxRates(bytes32 partition) external view returns (uint256 transferTaxRate, uint256 dividendTaxRate) {
        TaxRate memory rate = taxRates[partition];
        return (rate.transferTaxRate, rate.dividendTaxRate);
    }
}
```

### **Key Features of the Contract:**

1. **Restricted Token Transfers:**
   - Integrates with the ERC1404 standard to restrict token transfers based on compliance rules.
   - Only compliant participants can hold or transfer tokens, ensuring regulatory compliance.

2. **Tax Compliance:**
   - Calculates and withholds taxes on token transfers and dividend payments.
   - Reports withheld taxes to a designated tax authority, ensuring compliance with tax regulations.

3. **Role-Based Access Control:**
   - Compliance officers can set and update tax rates, ensuring that only authorized personnel manage tax operations.
   - The owner can add or remove compliance officers as needed.

4. **Dynamic Tax Rates:**
   - Allows compliance officers to set different tax rates for various partitions (e.g., different token classes).
   - Supports both transfer and dividend tax rates.

5. **Event Logging:**
   - Logs events for tax withholding, tax rate updates, and tax authority changes, providing transparency for tax-related actions.

6. **Pausable Contract:**
   - The owner can pause and unpause the contract to control restricted token transactions in emergency situations.

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

    const RestrictedTokenTaxComplianceContract = await hre.ethers.getContractFactory("RestrictedTokenTaxComplianceContract");
    const controllers = ["0xControllerAddress1", "0xControllerAddress2"]; // Replace with actual controller addresses
    const initialTaxAuthority = "0xTaxAuthorityAddress"; // Replace with actual tax authority address

    const contract = await RestrictedTokenTaxComplianceContract.deploy(
        "RestrictedToken", // Name of the restricted token
        "RST", // Symbol of the restricted token
        controllers,
        initialTaxAuthority
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
```

3. **Deployment:**
   - Compile and deploy the contract using Hardhat:
     ```bash
     npx hardhat compile
     npx hardhat run --network <network> scripts/deploy.js
     ```

4. **Testing:**
   - Write unit tests to ensure the contract behaves as expected under various conditions.
   - Include tests for tax calculations, tax rate updates, compliance rules, and restricted token transfers.

### **Additional Customization:**

1. **Dynamic Compliance Rules:**
   - Implement additional compliance rules that restrict token transfers based on jurisdictional regulations or other criteria.

2. **Oracle Integration:**
   - Use Chainlink oracles to fetch real-time data for dynamic tax rate adjustments based on market conditions.

3. **Audit and Security:**
   - Conduct a third-party security audit to ensure the contract's security and compliance.
   - Implement advanced testing and formal verification for critical functions.

4. **Front-End Dashboard:**
   - Develop a user interface for compliance officers

 to manage tax rates, view tax reports, and configure compliance settings.

This smart contract provides a robust framework for managing tax compliance on restricted token transactions, ensuring that all taxable events are accurately tracked and reported to relevant authorities.