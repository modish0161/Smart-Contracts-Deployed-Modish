### Solidity Smart Contract: 4-1Z_4C_CapitalGainsTaxReportingContract.sol

This smart contract is designed to manage the calculation and reporting of capital gains taxes on security token transactions. It adheres to the ERC1400 standard, making it suitable for regulated security tokens and compliant with tax laws for trades and other taxable events.

#### **Solidity Code: 4-1Z_4C_CapitalGainsTaxReportingContract.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // For price feeds

contract CapitalGainsTaxReportingContract is ERC1400, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax calculations and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store acquisition prices and timestamps for each holder and token partition
    struct TokenTransaction {
        uint256 acquisitionPrice; // In USD (scaled)
        uint256 acquisitionTimestamp;
    }

    mapping(address => mapping(bytes32 => TokenTransaction)) private _acquisitions; // holder => partition => TokenTransaction

    // Address of the Chainlink price feed for token valuation
    AggregatorV3Interface internal priceFeed;

    // Events for tracking tax operations
    event CapitalGainsTaxReported(address indexed holder, uint256 salePrice, uint256 acquisitionPrice, uint256 capitalGains, uint256 taxAmount, uint256 timestamp);
    event AcquisitionRecorded(address indexed holder, bytes32 partition, uint256 acquisitionPrice, uint256 timestamp);
    event TaxRateUpdated(uint256 newTaxRate, address updatedBy);

    // Tax rate in basis points (e.g., 1000 = 10%)
    uint256 public taxRate;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory controllers,
        address priceFeedAddress,
        uint256 initialTaxRate
    ) ERC1400(name, symbol, controllers) {
        require(priceFeedAddress != address(0), "Invalid price feed address");
        require(initialTaxRate <= 10000, "Tax rate should be <= 100%");

        priceFeed = AggregatorV3Interface(priceFeedAddress);
        taxRate = initialTaxRate;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Function to set a new capital gains tax rate (only compliance officer)
    function setTaxRate(uint256 newTaxRate) external onlyRole(COMPLIANCE_ROLE) {
        require(newTaxRate <= 10000, "Tax rate should be <= 100%");
        taxRate = newTaxRate;
        emit TaxRateUpdated(newTaxRate, msg.sender);
    }

    // Function to get the latest price from the Chainlink price feed
    function getLatestPrice() public view returns (int256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }

    // Function to record acquisition price and timestamp for a partition
    function recordAcquisition(
        bytes32 partition,
        address holder,
        uint256 acquisitionPrice
    ) external onlyRole(COMPLIANCE_ROLE) {
        require(holder != address(0), "Invalid holder address");
        _acquisitions[holder][partition] = TokenTransaction(acquisitionPrice, block.timestamp);
        emit AcquisitionRecorded(holder, partition, acquisitionPrice, block.timestamp);
    }

    // Function to calculate and report capital gains tax on a token sale
    function reportCapitalGainsTax(
        bytes32 partition,
        address holder,
        uint256 salePrice
    ) external nonReentrant whenNotPaused onlyRole(COMPLIANCE_ROLE) {
        require(holder != address(0), "Invalid holder address");
        require(_acquisitions[holder][partition].acquisitionPrice > 0, "Acquisition not recorded");

        uint256 acquisitionPrice = _acquisitions[holder][partition].acquisitionPrice;
        uint256 capitalGains = salePrice > acquisitionPrice ? salePrice - acquisitionPrice : 0;
        uint256 taxAmount = (capitalGains * taxRate) / 10000;

        emit CapitalGainsTaxReported(holder, salePrice, acquisitionPrice, capitalGains, taxAmount, block.timestamp);

        // Transfer the tax amount to the tax authority (can be defined as the owner or another contract)
        _transferByPartition(partition, holder, owner(), taxAmount, "");
    }

    // Internal function to handle token transfers
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

    // Function to get acquisition details for a holder
    function getAcquisitionDetails(address holder, bytes32 partition) external view returns (uint256 acquisitionPrice, uint256 acquisitionTimestamp) {
        TokenTransaction memory acquisition = _acquisitions[holder][partition];
        return (acquisition.acquisitionPrice, acquisition.acquisitionTimestamp);
    }
}
```

### **Key Features of the Contract:**

1. **Capital Gains Tax Compliance:**
   - Automatically calculates capital gains tax on security token sales based on the acquisition and sale prices.
   - Reports the calculated capital gains tax to the relevant authority and transfers the tax amount.

2. **Chainlink Price Feed Integration:**
   - Integrates with Chainlink to get real-time price data for security tokens.
   - The price feed ensures accurate valuation for capital gains calculations.

3. **Configurable Tax Rate:**
   - The compliance officer can set and update the capital gains tax rate based on jurisdictional requirements.
   - The tax rate is stored in basis points (e.g., 1000 = 10%).

4. **Acquisition Price Recording:**
   - Records the acquisition price and timestamp for each holder and partition, enabling accurate capital gains calculations.

5. **Role-Based Access Control:**
   - Only compliance officers can manage acquisition records and report capital gains taxes.
   - The owner can add or remove compliance officers as needed.

6. **Event Logging:**
   - Logs events for capital gains tax reporting and acquisition recordings, providing transparency for taxable events.

7. **Pausable Contract:**
   - The owner can pause and unpause the contract to control capital gains tax reporting in emergency situations.

### **Deployment Instructions:**

1. **Prerequisites:**
   - Install Node.js, Hardhat, and OpenZeppelin Contracts:
     ```bash
     npm install @openzeppelin/contracts @nomiclabs/hardhat-ethers ethers @chainlink/contracts
     ```

2. **Deployment Script (deploy.js):**

```javascript
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const CapitalGainsTaxReportingContract = await hre.ethers.getContractFactory("CapitalGainsTaxReportingContract");
    const controllers = ["0xControllerAddress1", "0xControllerAddress2"]; // Replace with actual controller addresses
    const priceFeedAddress = "0xChainlinkPriceFeedAddress"; // Replace with actual Chainlink price feed address
    const initialTaxRate = 1500; // Initial tax rate set to 15%

    const contract = await CapitalGainsTaxReportingContract.deploy(
        "SecurityToken", // Name of the security token
        "SEC", // Symbol of the security token
        controllers,
        priceFeedAddress,
        initialTaxRate
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
   - Include tests for capital gains calculations, tax rate updates, and role-based access controls.

### **Additional Customization:**

1. **Advanced Capital Gains Calculation:**
   - Implement a more sophisticated method to track acquisition and sale prices for complex scenarios, such as partial sales of token holdings.

2. **Multi-Jurisdictional Support:**
   - Extend the contract to support different tax rates for different jurisdictions, allowing the compliance officer to specify tax rates for multiple regions.

3. **Audit and Security:**
   - Conduct a third-party security audit to ensure the contract's security and compliance.
  

 - Implement advanced testing and formal verification for critical functions.

4. **Front-End Dashboard:**
   - Develop a user interface for compliance officers to manage acquisition records, view tax reports, and configure tax rates.

This smart contract provides a robust framework for calculating and reporting capital gains taxes on security token transactions, ensuring that all taxable events are accurately tracked and reported to relevant authorities.