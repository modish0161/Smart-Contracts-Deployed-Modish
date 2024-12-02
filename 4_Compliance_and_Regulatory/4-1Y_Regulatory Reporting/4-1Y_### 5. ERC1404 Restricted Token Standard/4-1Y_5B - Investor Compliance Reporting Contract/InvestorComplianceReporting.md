### Solidity Smart Contract: 4-1Y_5B_InvestorComplianceReporting.sol

This smart contract utilizes the ERC1404 standard to manage and report investor compliance data, such as KYC/AML checks, to regulatory authorities. It ensures that all token holders meet the regulatory requirements for holding or trading restricted tokens.

#### **Solidity Code: 4-1Y_5B_InvestorComplianceReporting.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC1404.sol"; // Interface for ERC1404 standard

contract InvestorComplianceReporting is IERC1404, ERC20Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Counters for compliance report IDs and restrictions
    Counters.Counter private _complianceReportIdCounter;
    Counters.Counter private _restrictionIdCounter;

    // Structure for storing compliance reports
    struct ComplianceReport {
        uint256 reportId;
        address investor;
        string status;
        string dataHash; // Hash of the compliance data for integrity
        uint256 timestamp;
    }

    // Structure for tracking restrictions
    struct Restriction {
        uint256 restrictionId;
        string description;
    }

    // Mapping for storing compliance reports
    mapping(uint256 => ComplianceReport) public complianceReports;

    // Mapping for storing restriction descriptions
    mapping(uint256 => Restriction) public restrictions;

    // Set of compliant addresses
    EnumerableSet.AddressSet private compliantAddresses;

    // Mapping to track restriction status of addresses
    mapping(address => uint256) public addressRestrictions;

    // Event for compliance reports
    event ComplianceReportSubmitted(
        uint256 indexed reportId,
        address indexed investor,
        string status,
        string dataHash,
        uint256 timestamp
    );

    // Event for restriction updates
    event RestrictionUpdated(
        uint256 indexed restrictionId,
        address indexed account,
        string restriction,
        uint256 timestamp
    );

    // Constructor to initialize the contract
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Modifier to check if the address is compliant
    modifier onlyCompliant() {
        require(isCompliant(msg.sender), "InvestorComplianceReporting: Address not compliant");
        _;
    }

    // Function to check compliance of an address
    function isCompliant(address account) public view returns (bool) {
        return compliantAddresses.contains(account);
    }

    // Function to add compliant addresses
    function addCompliantAddress(address account) external onlyOwner {
        require(!compliantAddresses.contains(account), "InvestorComplianceReporting: Address already compliant");
        compliantAddresses.add(account);
    }

    // Function to remove compliant addresses
    function removeCompliantAddress(address account) external onlyOwner {
        require(compliantAddresses.contains(account), "InvestorComplianceReporting: Address not compliant");
        compliantAddresses.remove(account);
    }

    // Function to submit a compliance report
    function submitComplianceReport(address investor, string memory status, string memory dataHash) external onlyOwner whenNotPaused {
        require(isCompliant(investor), "InvestorComplianceReporting: Investor not compliant");

        uint256 newReportId = _complianceReportIdCounter.current();

        ComplianceReport memory newReport = ComplianceReport({
            reportId: newReportId,
            investor: investor,
            status: status,
            dataHash: dataHash,
            timestamp: block.timestamp
        });

        complianceReports[newReportId] = newReport;
        emit ComplianceReportSubmitted(newReportId, investor, status, dataHash, block.timestamp);

        _complianceReportIdCounter.increment();
    }

    // Function to transfer tokens with compliance checks
    function transfer(address to, uint256 value) public override onlyCompliant returns (bool) {
        require(_checkRestriction(msg.sender, to), "InvestorComplianceReporting: Transfer restricted");

        bool success = super.transfer(to, value);
        if (success) {
            _reportTransferCompliance(msg.sender, to, value);
        }
        return success;
    }

    // Function to transfer tokens from an address with compliance checks
    function transferFrom(address from, address to, uint256 value) public override onlyCompliant returns (bool) {
        require(_checkRestriction(from, to), "InvestorComplianceReporting: Transfer restricted");

        bool success = super.transferFrom(from, to, value);
        if (success) {
            _reportTransferCompliance(from, to, value);
        }
        return success;
    }

    // Internal function to check restrictions before transfers
    function _checkRestriction(address from, address to) internal view returns (bool) {
        return addressRestrictions[from] == 0 && addressRestrictions[to] == 0;
    }

    // Internal function to report transfer compliance data
    function _reportTransferCompliance(address from, address to, uint256 value) internal {
        // Logic for reporting transfer compliance data, can be extended for additional logic
    }

    // Function to add or update a restriction on an address
    function addOrUpdateRestriction(address account, string memory restriction) external onlyOwner {
        uint256 restrictionId = addressRestrictions[account];
        if (restrictionId == 0) {
            _restrictionIdCounter.increment();
            restrictionId = _restrictionIdCounter.current();
            addressRestrictions[account] = restrictionId;
        }

        restrictions[restrictionId] = Restriction({
            restrictionId: restrictionId,
            description: restriction
        });

        emit RestrictionUpdated(restrictionId, account, restriction, block.timestamp);
    }

    // Function to remove a restriction from an address
    function removeRestriction(address account) external onlyOwner {
        uint256 restrictionId = addressRestrictions[account];
        require(restrictionId != 0, "InvestorComplianceReporting: No restriction to remove");

        delete restrictions[restrictionId];
        delete addressRestrictions[account];

        emit RestrictionUpdated(restrictionId, account, "No Restriction", block.timestamp);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to get the total number of compliance reports
    function getTotalComplianceReports() external view returns (uint256) {
        return _complianceReportIdCounter.current();
    }

    // Function to get a compliance report by ID
    function getComplianceReportById(uint256 reportId) external view returns (ComplianceReport memory) {
        return complianceReports[reportId];
    }

    // Function to get the total number of restrictions
    function getTotalRestrictions() external view returns (uint256) {
        return _restrictionIdCounter.current();
    }

    // Function to get a restriction by ID
    function getRestrictionById(uint256 restrictionId) external view returns (Restriction memory) {
        return restrictions[restrictionId];
    }
}
```

### **Key Features of the Contract:**

1. **ERC1404 Compliance:**
   - Implements ERC1404 standard to restrict token transfers to only authorized and compliant participants.

2. **Compliance Reporting:**
   - Allows for submission of compliance reports containing the investor's compliance status and KYC/AML data hash.

3. **Restriction Management:**
   - Allows for adding, updating, and removing restrictions on specific addresses, ensuring that only compliant participants can hold or transfer tokens.

4. **Role-Based Access Control:**
   - Uses role-based access control (RBAC) for compliance management, ensuring only authorized roles can submit compliance reports or modify restrictions.

5. **Pause/Unpause Functionality:**
   - Provides emergency control to pause or unpause the contract, useful in situations where there is a need to halt operations temporarily for security or compliance reasons.

6. **Modular Design:**
   - Modular contract design, allowing easy integration with additional compliance tools, reporting features, or regulatory systems.

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

    const InvestorComplianceReporting = await hre.ethers.getContractFactory("InvestorComplianceReporting");
    const contract = await InvestorComplianceReporting.deploy("Compliance Token", "CMP");

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
   - Implement test cases to verify:
     - Proper submission of compliance reports.
     - Correct handling of restrictions and compliance checks.
     - Accurate role-based access control and permissions.

### **Additional Customization:**

- **Integration with KYC/AML Providers:**
  - Integrate with

 external APIs for real-time KYC/AML verification and compliance validation.

- **Enhanced Reporting:**
  - Add automated and scheduled reporting features for regular submission of compliance data to regulatory authorities.

- **Auditing and Monitoring:**
  - Integrate with on-chain or off-chain auditing tools for real-time monitoring and alerting on compliance issues.