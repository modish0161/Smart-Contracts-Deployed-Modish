### Smart Contract: `SecurityTokenReinvestmentContract.sol`

This contract enables the automatic reinvestment of dividends or profits from tokenized securities (e.g., stocks or bonds) into additional security tokens or other compliant assets. It leverages the ERC1400 standard, which is tailored for security tokens with built-in compliance features.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SecurityTokenReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    // ERC1400 Token Interface
    ERC1400 public securityToken;

    // Performance Metrics Oracle Interface
    AggregatorV3Interface public performanceOracle;

    // Mapping to store user balances for each partition
    mapping(address => mapping(bytes32 => uint256)) public userTokenBalances;

    // Reinvestment Strategy
    mapping(address => ReinvestmentStrategy) public reinvestmentStrategies;

    // Struct to define a reinvestment strategy
    struct ReinvestmentStrategy {
        bytes32[] partitions; // Token partitions to reinvest into
        uint256[] percentages; // Percentages for each partition
    }

    // Event declarations
    event ProfitsDeposited(address indexed user, bytes32 partition, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 totalAmount, bytes32[] partitions, uint256[] amounts);
    event ReinvestmentStrategyUpdated(address indexed user, bytes32[] partitions, uint256[] percentages);
    event OracleUpdated(address indexed oracle);
    event SecurityTokenUpdated(address indexed tokenAddress);

    // Constructor to initialize the contract with the security token and oracle address
    constructor(address _securityToken, address _performanceOracle) {
        require(_securityToken != address(0), "Invalid security token address");
        require(_performanceOracle != address(0), "Invalid oracle address");

        securityToken = ERC1400(_securityToken);
        performanceOracle = AggregatorV3Interface(_performanceOracle);
    }

    // Function to deposit profits (ERC1400 tokens)
    function depositProfits(bytes32 partition, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        securityToken.operatorTransferByPartition(partition, msg.sender, address(this), amount, "", "");
        userTokenBalances[msg.sender][partition] += amount;

        emit ProfitsDeposited(msg.sender, partition, amount);
    }

    // Function to set reinvestment strategy for the user
    function setReinvestmentStrategy(bytes32[] calldata partitions, uint256[] calldata percentages) external whenNotPaused {
        require(partitions.length == percentages.length, "Partitions and percentages length mismatch");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }
        require(totalPercentage == 100, "Total percentage must equal 100");

        reinvestmentStrategies[msg.sender] = ReinvestmentStrategy({
            partitions: partitions,
            percentages: percentages
        });

        emit ReinvestmentStrategyUpdated(msg.sender, partitions, percentages);
    }

    // Function to batch reinvest profits based on the user's strategy
    function batchReinvestProfits(bytes32 partition, uint256 amount) external whenNotPaused nonReentrant {
        require(userTokenBalances[msg.sender][partition] >= amount, "Insufficient balance for reinvestment");

        ReinvestmentStrategy memory strategy = reinvestmentStrategies[msg.sender];
        require(strategy.partitions.length > 0, "Reinvestment strategy not set");

        uint256 totalReinvested = 0;
        uint256[] memory reinvestAmounts = new uint256[](strategy.partitions.length);

        for (uint256 i = 0; i < strategy.partitions.length; i++) {
            uint256 reinvestAmount = (amount * strategy.percentages[i]) / 100;
            securityToken.operatorTransferByPartition(partition, address(this), msg.sender, reinvestAmount, "", "");
            reinvestAmounts[i] = reinvestAmount;
            totalReinvested += reinvestAmount;
        }

        userTokenBalances[msg.sender][partition] -= amount;

        emit ProfitsReinvested(msg.sender, totalReinvested, strategy.partitions, reinvestAmounts);
    }

    // Function to update the performance oracle
    function updateOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address");
        performanceOracle = AggregatorV3Interface(newOracle);
        emit OracleUpdated(newOracle);
    }

    // Function to update the security token address
    function updateSecurityToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        securityToken = ERC1400(newTokenAddress);
        emit SecurityTokenUpdated(newTokenAddress);
    }

    // Function to pause the contract (admin only)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (admin only)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to transfer ownership of the contract
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        _transferOwnership(newOwner);
    }
}
```

### Key Features and Functionalities:

1. **Profit Deposit and Reinvestment**:
   - `depositProfits()`: Allows users to deposit profits in the form of ERC1400 security tokens with specific partitions.
   - `setReinvestmentStrategy()`: Allows users to set their reinvestment strategy by specifying partitions and percentages for each partition.
   - `batchReinvestProfits()`: Reinvests profits across multiple security tokens or partitions based on the user's predefined strategy.

2. **Reinvestment Strategy Management**:
   - Users can define their own reinvestment strategy by specifying partitions and the percentage of profits to be reinvested into each partition.

3. **Oracle Integration**:
   - The contract can integrate with an external oracle to fetch performance metrics, enabling strategic reinvestment based on performance data (not currently used in this version).

4. **Administrative Controls**:
   - `updateOracle()` and `updateSecurityToken()`: Allows the contract owner to update the performance oracle and security token address.
   - `pause()` and `unpause()`: Allows the contract owner to pause and resume contract operations for security or administrative reasons.

5. **Compliance Features**:
   - Supports ERC1400 compliance requirements such as partitions for regulated securities.
   - Reinforces KYC/AML checks through a whitelist (not currently implemented in this version but required for real-world deployment).

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const securityTokenAddress = "0x123..."; // Replace with actual security token address
  const performanceOracleAddress = "0x456..."; // Replace with actual oracle address

  console.log("Deploying contracts with the account:", deployer.address);

  const SecurityTokenReinvestmentContract = await ethers.getContractFactory("SecurityTokenReinvestmentContract");
  const contract = await SecurityTokenReinvestmentContract.deploy(securityTokenAddress, performanceOracleAddress);

  console.log("SecurityTokenReinvestmentContract deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
```

Run the deployment script using:

```bash
npx hardhat run scripts/deploy.js --network <network>
```

### Test Suite

Create a test suite for the contract:

```javascript
const { expect } = require("chai");

describe("SecurityTokenReinvestmentContract", function () {
  let SecurityTokenReinvestmentContract, contract, owner, addr1, addr2, securityToken, mockOracle;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC1400 token for testing
    const ERC1400Mock = await ethers.getContractFactory("ERC1400Mock");
    securityToken = await ERC1400Mock.deploy();

    // Mock Oracle for testing
    const MockOracle = await ethers.getContractFactory("MockOracle");
    mockOracle = await MockOracle.deploy(100);

    SecurityTokenReinvestmentContract = await ethers.getContractFactory("SecurityTokenReinvestmentContract");
    contract = await SecurityTokenReinvestmentContract.deploy(securityToken.address, mockOracle.address);
    await contract.deployed();

    // Mint some tokens to addr1 for testing
    await securityToken.issueByPartition("0x01", addr1.address, 100, "");
    await securityToken.issueByPartition("0x02", addr1.address, 100, "");
  });

  it("Should allow user to deposit profits", async function () {
    await securityToken.connect(addr1).operatorTransferByPartition("0x01", addr1.address, contract.address, 50, "", "");
    await contract.connect(addr1).depositProfits("0x01", 50);

    expect(await contract.userTokenBalances(addr1.address, "0x01")).to.equal(50);
  });

  it("Should allow user to set reinvestment strategy", async function () {
    await contract.connect(addr1).setReinvestmentStrategy(["0x01", "0x02"], [60, 40]);

    const strategy = await contract.reinvestmentStrategies(addr1.address);
    expect(strategy.part

itions[0]).to.equal("0x01");
    expect(strategy.percentages[0]).to.equal(60);
  });

  it("Should reinvest profits based on strategy", async function () {
    await securityToken.connect(addr1).operatorTransferByPartition("0x01", addr1.address, contract.address, 50, "", "");
    await contract.connect(addr1).depositProfits("0x01", 50);
    await contract.connect(addr1).setReinvestmentStrategy(["0x01", "0x02"], [60, 40]);

    await contract.connect(addr1).batchReinvestProfits("0x01", 30);

    expect(await contract.userTokenBalances(addr1.address, "0x01")).to.equal(20);
    expect(await securityToken.balanceOfByPartition("0x01", addr1.address)).to.equal(18); // 60% of 30
    expect(await securityToken.balanceOfByPartition("0x02", addr1.address)).to.equal(12); // 40% of 30
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

### Additional Customization

1. **KYC/AML Integration**: Integrate a whitelist to ensure only compliant investors can participate.
2. **Compliance Checks**: Implement checks for each transaction to ensure regulatory adherence.
3. **Oracle Integration**: Use performance metrics from a live oracle to dynamically adjust reinvestment strategies.
4. **Governance**: Add governance features for on-chain decision-making and parameter updates.

This contract provides a robust foundation for a security token reinvestment platform, adhering to the ERC1400 standard while supporting advanced features for regulated environments.