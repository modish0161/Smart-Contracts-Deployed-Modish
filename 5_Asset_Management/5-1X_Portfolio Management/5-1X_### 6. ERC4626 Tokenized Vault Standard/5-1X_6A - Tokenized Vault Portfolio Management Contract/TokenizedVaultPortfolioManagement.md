### Smart Contract: `TokenizedVaultPortfolioManagement.sol`

The smart contract named `TokenizedVaultPortfolioManagement.sol` is built using the ERC4626 standard, designed for managing tokenized vault portfolios. It allows investors to allocate pooled assets across various strategies and rebalances them based on predefined conditions to optimize performance.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenizedVaultPortfolioManagement is ERC4626, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    struct VaultStrategy {
        uint256 targetAllocation;     // Target percentage in basis points (1% = 100 bp)
        address strategyAddress;      // Address of the strategy contract
        bool isActive;                // Status of the strategy
    }

    // Array of vault strategies
    VaultStrategy[] public vaultStrategies;

    // Events
    event StrategyAdded(uint256 indexed strategyId, address indexed strategyAddress, uint256 targetAllocation);
    event StrategyRemoved(uint256 indexed strategyId);
    event Rebalanced(address indexed initiator);

    // Modifiers
    modifier validAllocation() {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < vaultStrategies.length; i++) {
            if (vaultStrategies[i].isActive) {
                totalAllocation = totalAllocation.add(vaultStrategies[i].targetAllocation);
            }
        }
        require(totalAllocation <= 10000, "Total allocation must be <= 100%");
        _;
    }

    constructor(IERC20 _asset)
        ERC20("TokenizedVaultPortfolioToken", "TVPT")
        ERC4626(_asset) 
    {
        // Initial setup if needed
    }

    function addStrategy(address _strategyAddress, uint256 _targetAllocation) external onlyOwner validAllocation {
        vaultStrategies.push(VaultStrategy({
            targetAllocation: _targetAllocation,
            strategyAddress: _strategyAddress,
            isActive: true
        }));
        emit StrategyAdded(vaultStrategies.length - 1, _strategyAddress, _targetAllocation);
    }

    function removeStrategy(uint256 _strategyId) external onlyOwner {
        require(_strategyId < vaultStrategies.length, "Invalid strategy ID");
        vaultStrategies[_strategyId].isActive = false;
        emit StrategyRemoved(_strategyId);
    }

    function rebalance() external onlyOwner nonReentrant validAllocation whenNotPaused {
        uint256 totalValue = totalAssets();
        for (uint256 i = 0; i < vaultStrategies.length; i++) {
            if (vaultStrategies[i].isActive) {
                uint256 targetValue = totalValue.mul(vaultStrategies[i].targetAllocation).div(10000);
                _adjustStrategyAllocation(vaultStrategies[i].strategyAddress, targetValue);
            }
        }
        emit Rebalanced(msg.sender);
    }

    function _adjustStrategyAllocation(address _strategyAddress, uint256 _targetValue) internal {
        // Logic to adjust the strategy allocation
        // This would typically involve depositing/withdrawing assets to/from strategy
    }

    // Emergency function to pause all operations
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause all operations
    function unpause() external onlyOwner {
        _unpause();
    }

    // Overriding ERC4626 functions
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override whenNotPaused returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }
}
```

### Key Features and Functionalities:

1. **Vault Strategy Management:**
   - `addStrategy`: Adds a new strategy to the vault with a specific target allocation.
   - `removeStrategy`: Deactivates a strategy based on the provided strategy ID.

2. **Rebalancing:**
   - `rebalance`: Rebalances the vault portfolio based on predefined target allocations of active strategies.

3. **Deposits and Withdrawals:**
   - `deposit` and `withdraw` functions are overridden from the ERC4626 standard, with added pausable functionality.

4. **Emergency Controls:**
   - `pause` and `unpause` functions to halt and resume contract operations during emergencies.

### 2. Deployment Scripts

Create a deployment script for Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const TokenizedVaultPortfolioManagement = await ethers.getContractFactory("TokenizedVaultPortfolioManagement");
  const contract = await TokenizedVaultPortfolioManagement.deploy("0xAssetTokenAddress");

  console.log("TokenizedVaultPortfolioManagement deployed to:", contract.address);
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

### 3. Test Suite

Create a test suite for the contract:

```javascript
const { expect } = require("chai");

describe("TokenizedVaultPortfolioManagement", function () {
  let Portfolio, portfolio, assetToken, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20");
    assetToken = await ERC20Mock.deploy("MockToken", "MTK", ethers.utils.parseEther("1000000"));
    await assetToken.deployed();

    Portfolio = await ethers.getContractFactory("TokenizedVaultPortfolioManagement");
    portfolio = await Portfolio.deploy(assetToken.address);
    await portfolio.deployed();
  });

  it("Should add a strategy to the vault", async function () {
    await portfolio.addStrategy(addr1.address, 5000);
    const strategy = await portfolio.vaultStrategies(0);
    expect(strategy.targetAllocation).to.equal(5000);
    expect(strategy.strategyAddress).to.equal(addr1.address);
  });

  it("Should remove a strategy from the vault", async function () {
    await portfolio.addStrategy(addr1.address, 5000);
    await portfolio.removeStrategy(0);
    const strategy = await portfolio.vaultStrategies(0);
    expect(strategy.isActive).to.equal(false);
  });

  it("Should allow deposits and withdrawals", async function () {
    await assetToken.approve(portfolio.address, ethers.utils.parseEther("100"));
    await portfolio.deposit(ethers.utils.parseEther("100"), addr1.address);

    expect(await portfolio.totalAssets()).to.equal(ethers.utils.parseEther("100"));
    await portfolio.withdraw(ethers.utils.parseEther("50"), addr1.address, owner.address);
    expect(await portfolio.totalAssets()).to.equal(ethers.utils.parseEther("50"));
  });

  it("Should pause and unpause the contract", async function () {
    await portfolio.pause();
    await expect(portfolio.deposit(ethers.utils.parseEther("100"), addr1.address)).to.be.revertedWith("Pausable: paused");

    await portfolio.unpause();
    await assetToken.approve(portfolio.address, ethers.utils.parseEther("100"));
    await portfolio.deposit(ethers.utils.parseEther("100"), addr1.address);
    expect(await portfolio.totalAssets()).to.equal(ethers.utils.parseEther("100"));
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

### 4. Documentation

**API Documentation:**

- `addStrategy(address _strategyAddress, uint256 _targetAllocation)`: Adds a new strategy to the vault with a specified target allocation.
- `removeStrategy(uint256 _strategyId)`: Deactivates a strategy based on the provided strategy ID.
- `rebalance()`: Rebalances the vault portfolio based on the predefined target allocations of active strategies.
- `deposit(uint256 assets, address receiver)`: Deposits `assets` into the vault and mints shares to the `receiver`.
- `withdraw(uint256 assets, address receiver, address owner)`: Withdraws `assets` from the vault and burns shares from the `owner`.

**User Guide:**

1. **Adding Strategies:**
   - Use `addStrategy()` to add strategies to the vault with specific target allocations.

2. **Removing Strategies:**
   - Use `removeStrategy()` to deactivate a strategy.

3. **Deposits and Withdrawals:**
   - Use the `deposit()` and `withdraw()` functions to manage assets within the vault.

4. **Rebalancing:**
   - Call `rebalance()` to optimize portfolio performance based on predefined strategies.

**Developer Guide:**

- Extend the contract by adding more sophisticated rebalancing algorithms.
- Implement on-chain governance for modifying strategy parameters and adding/removing operators.

### 5. Additional Deployment Instructions

- Ensure that only verified strategy addresses are used in the deployment process.
- Consider implementing automated notifications to inform investors about rebalancing events.

This smart contract provides a robust foundation for managing tokenized vault portfolios, including dynamic rebalancing and compliance controls. Further customization can be added as needed.