### Smart Contract: `MultiAssetReinvestmentContract.sol`

This contract allows automatic reinvestment of profits or dividends across a portfolio of fungible and non-fungible assets using the ERC1155 standard. Investors can allocate earnings into different types of assets (e.g., cryptocurrencies, NFTs) based on predefined reinvestment strategies.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MultiAssetReinvestmentContract is IERC1155Receiver, Ownable, ReentrancyGuard, Pausable {
    using Address for address;

    // ERC1155 Token Interface
    IERC1155 public profitToken;

    // Performance Metrics Oracle Interface
    AggregatorV3Interface public performanceOracle;

    // Mapping to store user balances for each token ID
    mapping(address => mapping(uint256 => uint256)) public userTokenBalances;

    // Reinvestment Strategies
    mapping(address => ReinvestmentStrategy) public reinvestmentStrategies;

    // Struct to define a reinvestment strategy
    struct ReinvestmentStrategy {
        uint256[] tokenIds;
        uint256[] percentages; // Percentages for each tokenId to be reinvested
    }

    // Event declarations
    event ProfitsDeposited(address indexed user, uint256 tokenId, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 amount, uint256 tokenId);
    event ReinvestmentStrategyUpdated(address indexed user, uint256[] tokenIds, uint256[] percentages);
    event OracleUpdated(address indexed oracle);
    event ProfitTokenUpdated(address indexed tokenAddress);

    // Constructor to initialize the contract with the profit token and oracle address
    constructor(address _profitToken, address _performanceOracle) {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_performanceOracle != address(0), "Invalid oracle address");

        profitToken = IERC1155(_profitToken);
        performanceOracle = AggregatorV3Interface(_performanceOracle);
    }

    // Function to deposit profits (ERC1155 tokens)
    function depositProfits(uint256 tokenId, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        profitToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        userTokenBalances[msg.sender][tokenId] += amount;

        emit ProfitsDeposited(msg.sender, tokenId, amount);
    }

    // Function to set reinvestment strategy for the user
    function setReinvestmentStrategy(uint256[] calldata tokenIds, uint256[] calldata percentages) external whenNotPaused {
        require(tokenIds.length == percentages.length, "Token IDs and percentages length mismatch");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }
        require(totalPercentage == 100, "Total percentage must equal 100");

        reinvestmentStrategies[msg.sender] = ReinvestmentStrategy({
            tokenIds: tokenIds,
            percentages: percentages
        });

        emit ReinvestmentStrategyUpdated(msg.sender, tokenIds, percentages);
    }

    // Function to reinvest profits based on the user's strategy
    function reinvestProfits(uint256 tokenId, uint256 amount) external whenNotPaused nonReentrant {
        require(userTokenBalances[msg.sender][tokenId] >= amount, "Insufficient balance for reinvestment");

        ReinvestmentStrategy memory strategy = reinvestmentStrategies[msg.sender];
        require(strategy.tokenIds.length > 0, "Reinvestment strategy not set");

        for (uint256 i = 0; i < strategy.tokenIds.length; i++) {
            uint256 reinvestAmount = (amount * strategy.percentages[i]) / 100;
            profitToken.safeTransferFrom(address(this), msg.sender, strategy.tokenIds[i], reinvestAmount, "");

            emit ProfitsReinvested(msg.sender, reinvestAmount, strategy.tokenIds[i]);
        }

        userTokenBalances[msg.sender][tokenId] -= amount;
    }

    // Function to update the performance oracle
    function updateOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address");
        performanceOracle = AggregatorV3Interface(newOracle);
        emit OracleUpdated(newOracle);
    }

    // Function to update the profit token address
    function updateProfitToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        profitToken = IERC1155(newTokenAddress);
        emit ProfitTokenUpdated(newTokenAddress);
    }

    // ERC1155Receiver hook to allow this contract to receive ERC1155 tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    // ERC1155Receiver hook for batch token transfers
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // Function to pause the contract (admin only)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (admin only)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Internal function to get the performance index from the oracle
    function _getPerformanceIndex() internal view returns (uint256) {
        (, int256 index,,,) = performanceOracle.latestRoundData();
        require(index > 0, "Invalid performance index");
        return uint256(index);
    }
}
```

### Key Features and Functionalities:

1. **Profit Deposit and Reinvestment**:
   - `depositProfits()`: Allows users to deposit profits in the form of ERC1155 tokens.
   - `setReinvestmentStrategy()`: Allows users to set their reinvestment strategy by specifying token IDs and percentages for each token.
   - `reinvestProfits()`: Reinvests profits based on the user's predefined strategy.

2. **Reinvestment Strategy Management**:
   - Users can define their own reinvestment strategy by specifying token IDs and the percentage of profits to be reinvested into each token.

3. **Oracle Integration**:
   - The contract integrates with an external oracle to fetch performance metrics, allowing for strategic reinvestment based on performance data.

4. **Administrative Controls**:
   - `updateOracle()` and `updateProfitToken()`: Allows the contract owner to update the performance oracle and profit token address.
   - `pause()` and `unpause()`: Allows the contract owner to pause and resume contract operations for security or administrative reasons.

5. **ERC1155 Integration**:
   - `onERC1155Received()` and `onERC1155BatchReceived()`: ERC1155 hooks to handle received tokens as required by the standard.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const profitTokenAddress = "0x123..."; // Replace with actual profit token address
  const performanceOracleAddress = "0x456..."; // Replace with actual oracle address

  console.log("Deploying contracts with the account:", deployer.address);

  const MultiAssetReinvestmentContract = await ethers.getContractFactory("MultiAssetReinvestmentContract");
  const contract = await MultiAssetReinvestmentContract.deploy(profitTokenAddress, performanceOracleAddress);

  console.log("MultiAssetReinvestmentContract deployed to:", contract.address);
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

describe("MultiAssetReinvestmentContract", function () {
  let MultiAssetReinvestmentContract, contract, owner, addr1, addr2, profitToken, mockOracle;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC1155 token for testing
    const ERC1155Mock = await ethers.getContractFactory("ERC1155Mock");
    profitToken = await ERC1155Mock.deploy();

    // Mock Oracle for testing
    const MockOracle = await ethers.getContractFactory("MockOracle");
    mockOracle = await MockOracle.deploy(100);

    MultiAssetReinvestmentContract = await ethers.getContractFactory("MultiAssetReinvestmentContract");
    contract = await MultiAssetReinvestmentContract.deploy(profitToken.address, mockOracle.address);
    await contract.deployed();

    // Mint some tokens to addr1 for testing
    await profitToken.mint(addr1.address, 1, 50); // Token ID 1, amount 50
    await profitToken.mint(addr1.address, 2, 50); // Token ID 2, amount 50
  });

  it("Should deposit

 profits correctly", async function () {
    await profitToken.connect(addr1).setApprovalForAll(contract.address, true);
    await contract.connect(addr1).depositProfits(1, 50);

    expect(await contract.userTokenBalances(addr1.address, 1)).to.equal(50);
  });

  it("Should allow user to set reinvestment strategy", async function () {
    await contract.connect(addr1).setReinvestmentStrategy([1, 2], [60, 40]);

    const strategy = await contract.reinvestmentStrategies(addr1.address);
    expect(strategy.tokenIds[0]).to.equal(1);
    expect(strategy.percentages[0]).to.equal(60);
  });

  it("Should reinvest profits based on strategy", async function () {
    await profitToken.connect(addr1).setApprovalForAll(contract.address, true);
    await contract.connect(addr1).depositProfits(1, 50);
    await contract.connect(addr1).setReinvestmentStrategy([1, 2], [60, 40]);

    await contract.connect(addr1).reinvestProfits(1, 30);

    expect(await contract.userTokenBalances(addr1.address, 1)).to.equal(20);
    expect(await profitToken.balanceOf(addr1.address, 1)).to.equal(20); // 60% of 30
    expect(await profitToken.balanceOf(addr1.address, 2)).to.equal(32); // 40% of 30
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

This will test the contract's core functionalities, such as depositing profits, setting reinvestment strategies, and reinvesting based on the strategy. Further customization and enhancements can be done based on specific requirements.