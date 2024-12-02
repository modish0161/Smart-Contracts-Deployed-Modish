### Solidity Smart Contract: 4-1Z_6C_WithdrawalTaxReportingContract.sol

This contract is designed to automate the reporting of taxable withdrawals from tokenized vaults under the ERC4626 standard. It ensures that all funds withdrawn from the vault are taxed and reported according to applicable regulations, such as capital gains or income tax on redeemed tokens.

#### **Solidity Code: 4-1Z_6C_WithdrawalTaxReportingContract.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract WithdrawalTaxReportingContract is ERC4626, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers to manage tax settings and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Tax rates for withdrawals (in basis points, where 10000 = 100%)
    uint256 public withdrawalTaxRate;

    // Address of the tax authority for remittance
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxRateUpdated(uint256 withdrawalTaxRate, address updatedBy);
    event TaxWithheld(address indexed investor, uint256 withdrawalTax, address indexed taxAuthority);
    event TaxAuthorityUpdated(address oldTaxAuthority, address newTaxAuthority);

    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        uint256 _withdrawalTaxRate,
        address initialTaxAuthority
    ) ERC4626(asset, name, symbol) {
        require(_withdrawalTaxRate <= 10000, "Invalid tax rate");
        require(initialTaxAuthority != address(0), "Invalid tax authority address");

        withdrawalTaxRate = _withdrawalTaxRate;
        taxAuthority = initialTaxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Modifier to restrict function access to compliance officers
    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), "Caller is not a compliance officer");
        _;
    }

    // Function to set the withdrawal tax rate (only by compliance officers)
    function setWithdrawalTaxRate(uint256 _withdrawalTaxRate) external onlyComplianceOfficer {
        require(_withdrawalTaxRate <= 10000, "Invalid tax rate");
        withdrawalTaxRate = _withdrawalTaxRate;
        emit TaxRateUpdated(withdrawalTaxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Override withdraw function to withhold tax on withdrawals
    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant whenNotPaused returns (uint256) {
        uint256 shares = super.withdraw(assets, receiver, owner);

        // Calculate and withhold withdrawal tax
        uint256 withdrawalTax = (assets * withdrawalTaxRate) / 10000;
        _withholdTax(owner, withdrawalTax);

        return shares;
    }

    // Internal function to withhold tax
    function _withholdTax(address investor, uint256 withdrawalTax) internal {
        if (withdrawalTax > 0) {
            IERC20(asset()).transferFrom(investor, taxAuthority, withdrawalTax);
            emit TaxWithheld(investor, withdrawalTax, taxAuthority);
        }
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

    // Function to get the current tax rate
    function getWithdrawalTaxRate() external view returns (uint256) {
        return withdrawalTaxRate;
    }
}
```

### **Key Features of the Contract:**

1. **Withdrawal Tax Withholding:**
   - Automatically calculates and withholds taxes on withdrawals from the vault.
   - Transfers the withheld taxes directly to the tax authority address.

2. **Dynamic Tax Rate:**
   - Compliance officers can update the tax rate for withdrawals, allowing for regulatory adjustments and market changes.

3. **Role-Based Access Control:**
   - Compliance officers have control over tax rate adjustments and tax reporting.
   - The contract owner can add or remove compliance officers and set the tax authority address.

4. **Pausable Contract:**
   - The contract can be paused or unpaused by the owner, adding an additional layer of security in case of emergency.

5. **Event Logging:**
   - Logs events for tax rate updates, tax withholding, and tax authority changes to ensure transparency and auditability.

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

    const WithdrawalTaxReportingContract = await hre.ethers.getContractFactory("WithdrawalTaxReportingContract");
    const assetAddress = "0xAssetTokenAddress"; // Replace with the actual ERC20 token address used as asset in the vault
    const initialTaxAuthority = "0xTaxAuthorityAddress"; // Replace with the actual tax authority address
    const withdrawalTaxRate = 500; // Set initial withdrawal tax rate (in basis points)

    const contract = await WithdrawalTaxReportingContract.deploy(
        assetAddress,
        "VaultToken", // Name of the vault token
        "VTK", // Symbol of the vault token
        withdrawalTaxRate,
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
   - Write unit tests to verify the correct behavior of tax withholding, tax rate updates, compliance rules, and vault token transactions.
   - Include edge cases to ensure the contract handles all expected scenarios.

### **Additional Customization:**

1. **Advanced Tax Calculation:**
   - Implement more sophisticated logic for calculating tax based on investor's positions, withdrawal history, and applicable tax brackets.

2. **Oracle Integration:**
   - Use Chainlink oracles to fetch real-time data for dynamic tax rate adjustments based on regulatory changes or market conditions.

3. **User Dashboard:**
   - Develop a front-end interface to show investors their tax obligations, transaction history, and compliance status.

This contract provides a comprehensive solution for automating tax reporting and compliance for withdrawals from tokenized vaults under the ERC4626 standard, ensuring regulatory adherence and security.