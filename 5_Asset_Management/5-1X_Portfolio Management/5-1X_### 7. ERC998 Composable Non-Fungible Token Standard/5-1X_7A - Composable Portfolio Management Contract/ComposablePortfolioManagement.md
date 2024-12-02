### Smart Contract: `ComposablePortfolioManagement.sol`

The `ComposablePortfolioManagement.sol` contract utilizes the ERC998 composable non-fungible token standard to manage token portfolios that can own other tokens, enabling complex, nested portfolio structures. This contract is designed to rebalance the portfolio based on performance or risk tolerance, providing a secure and modular foundation for composable asset management.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";

contract ComposablePortfolioManagement is ERC998TopDown, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Counter for tracking token IDs
    Counters.Counter private _tokenIdCounter;

    // Struct to represent a rebalancing strategy
    struct RebalancingStrategy {
        uint256 targetAllocation; // Target allocation percentage in basis points (1% = 100)
        address asset;            // Address of the asset to be rebalanced
        bool isActive;            // Status of the strategy
    }

    // Mapping from token ID to portfolio strategies
    mapping(uint256 => RebalancingStrategy[]) public portfolioStrategies;

    // Events
    event PortfolioCreated(uint256 indexed tokenId, address indexed owner);
    event StrategyAdded(uint256 indexed tokenId, uint256 indexed strategyId, address indexed asset, uint256 targetAllocation);
    event StrategyRemoved(uint256 indexed tokenId, uint256 indexed strategyId);
    event Rebalanced(uint256 indexed tokenId, address indexed initiator);

    // Constructor
    constructor() ERC721("ComposablePortfolio", "CPM") {}

    // Modifier to validate total allocation
    modifier validAllocation(uint256 tokenId) {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < portfolioStrategies[tokenId].length; i++) {
            if (portfolioStrategies[tokenId][i].isActive) {
                totalAllocation = totalAllocation.add(portfolioStrategies[tokenId][i].targetAllocation);
            }
        }
        require(totalAllocation <= 10000, "Total allocation must be <= 100%");
        _;
    }

    // Create a new composable portfolio
    function createPortfolio() external whenNotPaused nonReentrant returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(msg.sender, newTokenId);
        emit PortfolioCreated(newTokenId, msg.sender);
        return newTokenId;
    }

    // Add a rebalancing strategy to a portfolio
    function addStrategy(uint256 tokenId, address _asset, uint256 _targetAllocation)
        external
        onlyOwnerOf(tokenId)
        validAllocation(tokenId)
    {
        portfolioStrategies[tokenId].push(RebalancingStrategy({
            targetAllocation: _targetAllocation,
            asset: _asset,
            isActive: true
        }));
        emit StrategyAdded(tokenId, portfolioStrategies[tokenId].length - 1, _asset, _targetAllocation);
    }

    // Remove a rebalancing strategy from a portfolio
    function removeStrategy(uint256 tokenId, uint256 strategyId) external onlyOwnerOf(tokenId) {
        require(strategyId < portfolioStrategies[tokenId].length, "Invalid strategy ID");
        portfolioStrategies[tokenId][strategyId].isActive = false;
        emit StrategyRemoved(tokenId, strategyId);
    }

    // Rebalance the portfolio based on predefined strategies
    function rebalance(uint256 tokenId) external onlyOwnerOf(tokenId) nonReentrant whenNotPaused {
        require(_exists(tokenId), "Nonexistent portfolio");
        uint256 totalValue = totalAssets(tokenId);
        for (uint256 i = 0; i < portfolioStrategies[tokenId].length; i++) {
            if (portfolioStrategies[tokenId][i].isActive) {
                uint256 targetValue = totalValue.mul(portfolioStrategies[tokenId][i].targetAllocation).div(10000);
                _adjustAssetAllocation(tokenId, portfolioStrategies[tokenId][i].asset, targetValue);
            }
        }
        emit Rebalanced(tokenId, msg.sender);
    }

    // Internal function to adjust asset allocation
    function _adjustAssetAllocation(uint256 tokenId, address _asset, uint256 _targetValue) internal {
        // Custom logic to adjust asset allocation
        // Implement strategies to buy/sell assets or interact with DeFi protocols
    }

    // Return the total assets value of a portfolio
    function totalAssets(uint256 tokenId) public view returns (uint256) {
        // Implement logic to calculate the total value of assets in the portfolio
        return 0; // Placeholder value, should be replaced with actual logic
    }

    // Modifier to check if the caller is the owner of the token
    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        _;
    }

    // Pause and unpause functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
```

### Key Features and Functionalities:

1. **Composable Portfolio Management:**
   - `createPortfolio()`: Allows users to create a new composable portfolio, represented as a unique ERC998 token.
   - `addStrategy()`: Adds a rebalancing strategy to a specific portfolio based on the target allocation.
   - `removeStrategy()`: Deactivates a strategy for a specific portfolio.

2. **Rebalancing:**
   - `rebalance()`: Rebalances the portfolio's asset allocations according to the predefined strategies, adjusting the composition of underlying tokens.

3. **Portfolio Ownership:**
   - Each portfolio is represented by an ERC998 token, with ownership of the portfolio linked to the token holder.

4. **Emergency Controls:**
   - `pause` and `unpause`: Allows the contract owner to pause and resume operations during emergencies.

5. **Tokenized Portfolios:**
   - `totalAssets(uint256 tokenId)`: Returns the total value of assets in the portfolio (placeholder logic to be implemented based on actual asset values).

### Deployment Scripts

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const ComposablePortfolioManagement = await ethers.getContractFactory("ComposablePortfolioManagement");
  const contract = await ComposablePortfolioManagement.deploy();

  console.log("ComposablePortfolioManagement deployed to:", contract.address);
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

describe("ComposablePortfolioManagement", function () {
  let ComposablePortfolio, portfolio, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    ComposablePortfolio = await ethers.getContractFactory("ComposablePortfolioManagement");
    portfolio = await ComposablePortfolio.deploy();
    await portfolio.deployed();
  });

  it("Should create a new portfolio", async function () {
    await portfolio.createPortfolio();
    const ownerOfPortfolio = await portfolio.ownerOf(1);
    expect(ownerOfPortfolio).to.equal(owner.address);
  });

  it("Should add a strategy to the portfolio", async function () {
    await portfolio.createPortfolio();
    await portfolio.addStrategy(1, addr1.address, 5000);
    const strategy = await portfolio.portfolioStrategies(1, 0);
    expect(strategy.targetAllocation).to.equal(5000);
    expect(strategy.asset).to.equal(addr1.address);
  });

  it("Should remove a strategy from the portfolio", async function () {
    await portfolio.createPortfolio();
    await portfolio.addStrategy(1, addr1.address, 5000);
    await portfolio.removeStrategy(1, 0);
    const strategy = await portfolio.portfolioStrategies(1, 0);
    expect(strategy.isActive).to.equal(false);
  });

  it("Should rebalance the portfolio", async function () {
    await portfolio.createPortfolio();
    await portfolio.addStrategy(1, addr1.address, 5000);
    await portfolio.rebalance(1);
    // Add assertions based on rebalancing logic
  });

  it("Should pause and unpause the contract", async function () {
    await portfolio.pause();
    await expect(portfolio.createPortfolio()).to.be.revertedWith("Pausable: paused");

    await portfolio.unpause();
    await portfolio.createPortfolio();
    const ownerOfPortfolio = await portfolio.ownerOf(1);
    expect(ownerOfPortfolio).to.equal(owner.address);
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

### Documentation

**API Documentation:**

- `createPortfolio()`: Creates a new composable portfolio and mints a unique ERC998 token to represent it.
- `addStrategy(uint256 tokenId, address _asset, uint256 _targetAllocation)`: Adds a rebalancing strategy to the specified portfolio.
- `removeStrategy(uint256 tokenId, uint256 strategyId)`: Deactiv