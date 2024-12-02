### Solidity Smart Contract: 4-1Z_4B_DividendWithholdingTaxContract.sol

This smart contract is designed to manage dividend distributions for security token holders, automatically withholding taxes as required by law and reporting the withheld amounts to relevant authorities. It follows the ERC1400 standard, making it suitable for regulated securities.

#### **Solidity Code: 4-1Z_4B_DividendWithholdingTaxContract.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DividendWithholdingTaxContract is ERC1400, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax rates and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store withholding tax rates for different jurisdictions
    mapping(bytes32 => uint256) private _dividendTaxRates; // jurisdiction => taxRate (in basis points, e.g., 500 = 5%)

    // Address where collected taxes will be sent
    address public taxAuthority;

    // Events for tracking tax operations
    event DividendPaid(bytes32 indexed partition, address indexed holder, uint256 amount, uint256 taxAmount, uint256 timestamp);
    event TaxWithheld(bytes32 indexed partition, address indexed holder, uint256 amount, uint256 taxAmount, uint256 timestamp);
    event TaxRateUpdated(bytes32 indexed jurisdiction, uint256 newTaxRate, address updatedBy);
    event TaxAuthorityUpdated(address newTaxAuthority, address updatedBy);

    constructor(
        string memory name,
        string memory symbol,
        address[] memory controllers,
        address _taxAuthority
    ) ERC1400(name, symbol, controllers) {
        require(_taxAuthority != address(0), "Invalid tax authority address");

        taxAuthority = _taxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Function to set a new dividend tax rate for a specific jurisdiction (only compliance officer)
    function setDividendTaxRate(bytes32 jurisdiction, uint256 taxRate) external onlyRole(COMPLIANCE_ROLE) {
        require(taxRate <= 10000, "Tax rate should be less than or equal to 100%");
        _dividendTaxRates[jurisdiction] = taxRate;
        emit TaxRateUpdated(jurisdiction, taxRate, msg.sender);
    }

    // Function to get the dividend tax rate of a specific jurisdiction
    function getDividendTaxRate(bytes32 jurisdiction) external view returns (uint256) {
        return _dividendTaxRates[jurisdiction];
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address _taxAuthority) external onlyOwner {
        require(_taxAuthority != address(0), "Invalid tax authority address");
        taxAuthority = _taxAuthority;
        emit TaxAuthorityUpdated(_taxAuthority, msg.sender);
    }

    // Function to distribute dividends with tax withholding
    function distributeDividendsWithTax(
        bytes32 partition,
        address[] calldata holders,
        uint256[] calldata amounts,
        bytes32[] calldata jurisdictions
    ) external nonReentrant whenNotPaused onlyRole(COMPLIANCE_ROLE) {
        require(holders.length == amounts.length && amounts.length == jurisdictions.length, "Array lengths must match");

        for (uint256 i = 0; i < holders.length; i++) {
            uint256 taxRate = _dividendTaxRates[jurisdictions[i]];
            uint256 taxAmount = (amounts[i] * taxRate) / 10000;
            uint256 amountAfterTax = amounts[i] - taxAmount;

            _transferByPartition(partition, msg.sender, holders[i], amountAfterTax, "");
            _transferByPartition(partition, msg.sender, taxAuthority, taxAmount, "");

            emit DividendPaid(partition, holders[i], amounts[i], taxAmount, block.timestamp);
            emit TaxWithheld(partition, holders[i], amounts[i], taxAmount, block.timestamp);
        }
    }

    // Function to add a compliance officer (only owner)
    function addComplianceOfficer(address officer) external onlyOwner {
        grantRole(COMPLIANCE_ROLE, officer);
    }

    // Function to remove a compliance officer (only owner)
    function removeComplianceOfficer(address officer) external onlyOwner {
        revokeRole(COMPLIANCE_ROLE, officer);
    }

    // Function to pause the contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to get dividend tax details of a jurisdiction
    function getDividendTaxDetails(bytes32 jurisdiction, uint256 amount) external view returns (uint256 taxRate, uint256 taxAmount) {
        taxRate = _dividendTaxRates[jurisdiction];
        taxAmount = (amount * taxRate) / 10000;
    }

    // Internal function to handle transfer with dividend tax calculation
    function _transferByPartition(
        bytes32 partition,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1400: transfer to the zero address");
        _transferWithData(partition, from, to, value, data);
    }
}
```

### **Key Features of the Contract:**

1. **Dividend Tax Compliance:**
   - Automatically calculates and withholds taxes on dividend payments based on predefined tax rates for each jurisdiction.
   - Distributes dividends to token holders after withholding the appropriate taxes.

2. **Configurable Tax Rates:**
   - Compliance officers can set and update tax rates for different jurisdictions, ensuring compliance with current tax regulations.
   - Different jurisdictions can have distinct tax rates.

3. **Role-Based Access Control:**
   - Only compliance officers can manage tax rates and distribute dividends with tax withholding.
   - The owner can add or remove compliance officers as needed.

4. **Tax Reporting:**
   - Emits events for all dividend distributions and tax withholding activities, providing transparency and traceability for tax reporting.
   - Supports manual tax reporting to the tax authority if needed.

5. **Pausable Contract:**
   - The owner can pause and unpause the contract to control dividend distributions and tax withholding in emergency situations.

6. **Events for Transparency:**
   - Emits events such as `DividendPaid`, `TaxWithheld`, `TaxRateUpdated`, and `TaxAuthorityUpdated`.
   - Provides transparency for all taxable events.

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

    const DividendWithholdingTaxContract = await hre.ethers.getContractFactory("DividendWithholdingTaxContract");
    const controllers = ["0xControllerAddress1", "0xControllerAddress2"]; // Replace with actual controller addresses
    const taxAuthority = "0xYourTaxAuthorityAddress"; // Replace with actual tax authority address

    const contract = await DividendWithholdingTaxContract.deploy(
        "SecurityToken", // Name of the security token
        "SEC", // Symbol of the security token
        controllers,
        taxAuthority
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
   - Include tests for dividend distribution, tax withholding, tax rate updates, and role-based access controls.

### **Additional Customization:**

1. **Multi-Currency Support:**
   - Implement support for multiple currencies, enabling dividend distributions and tax withholding in different currencies.

2. **Integration with Oracles:**
   - Integrate with Chainlink oracles to update tax rates in real-time based on external data sources.

3. **Audit and Security:**
   - Conduct a third-party security audit to ensure the contract's security and compliance.
   - Implement advanced testing and formal verification for critical functions.

4. **Front-End Dashboard:**
   - Develop a user interface for compliance officers to manage tax rates, view tax reports, and distribute dividends.

This smart contract provides a robust framework for managing dividend distributions and tax compliance in security token transactions, ensuring that all taxable events are reported to authorities in a transparent and compliant manner.