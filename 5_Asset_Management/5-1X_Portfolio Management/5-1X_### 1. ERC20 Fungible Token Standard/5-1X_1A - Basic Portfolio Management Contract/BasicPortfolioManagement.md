Let's create a smart contract based on the provided specifications for "5-1X_1A - Basic Portfolio Management Contract" using the ERC20 standard. The contract will manage a portfolio of ERC20 tokens and allow investors to allocate, track performance, and rebalance based on predefined strategies.

### 1. Contract Code: `BasicPortfolioManagement.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BasicPortfolioManagement is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Structure to hold asset details
    struct Asset {
        IERC20 token;
        uint256 targetAllocation; // Target percentage (in basis points, 1% = 100 bp)
    }

    // Array to hold all assets in the portfolio
    Asset[] public assets;

    // Mapping to track investor balances in the portfolio
    mapping(address => uint256) public balances;

    // Total value of the portfolio in wei
    uint256 public totalPortfolioValue;

    // Events
    event Invested(address indexed investor, uint256 amount);
    event Withdrawn(address indexed investor, uint256 amount);
    event Rebalanced();
    event AssetAdded(IERC20 indexed token, uint256 targetAllocation);
    event AssetUpdated(IERC20 indexed token, uint256 newTargetAllocation);

    // Modifier to check that the total target allocation is 100%
    modifier validAllocation() {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            totalAllocation = totalAllocation.add(assets[i].targetAllocation);
        }
        require(totalAllocation == 10000, "Total allocation must be 100%");
        _;
    }

    // Function to add a new asset to the portfolio
    function addAsset(IERC20 _token, uint256 _targetAllocation) external onlyOwner validAllocation {
        assets.push(Asset({ token: _token, targetAllocation: _targetAllocation }));
        emit AssetAdded(_token, _targetAllocation);
    }

    // Function to update the target allocation of an existing asset
    function updateAsset(IERC20 _token, uint256 _newTargetAllocation) external onlyOwner validAllocation {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == _token) {
                assets[i].targetAllocation = _newTargetAllocation;
                emit AssetUpdated(_token, _newTargetAllocation);
                return;
            }
        }
    }

    // Function for investors to invest ETH into the portfolio
    function invest() external payable nonReentrant {
        require(msg.value > 0, "Investment amount must be greater than zero");
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalPortfolioValue = totalPortfolioValue.add(msg.value);
        emit Invested(msg.sender, msg.value);
    }

    // Function for investors to withdraw their investment
    function withdraw(uint256 _amount) external nonReentrant {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalPortfolioValue = totalPortfolioValue.sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    // Function to rebalance the portfolio based on the target allocations
    function rebalance() external onlyOwner nonReentrant validAllocation {
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 targetValue = totalPortfolioValue.mul(assets[i].targetAllocation).div(10000);
            uint256 currentBalance = assets[i].token.balanceOf(address(this));

            if (currentBalance > targetValue) {
                // Sell excess tokens
                uint256 excessAmount = currentBalance.sub(targetValue);
                assets[i].token.transfer(owner(), excessAmount);
            } else if (currentBalance < targetValue) {
                // Buy more tokens
                uint256 deficitAmount = targetValue.sub(currentBalance);
                assets[i].token.transferFrom(owner(), address(this), deficitAmount);
            }
        }
        emit Rebalanced();
    }

    // Function to view the target allocation of a specific asset
    function getAssetAllocation(IERC20 _token) external view returns (uint256) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == _token) {
                return assets[i].targetAllocation;
            }
        }
        return 0; // Asset not found
    }

    // Fallback function to handle ETH sent directly to the contract
    receive() external payable {
        invest();
    }
}
```

### 2. Deployment Scripts

Create a deployment script for Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const BasicPortfolioManagement = await ethers.getContractFactory("BasicPortfolioManagement");
  const contract = await BasicPortfolioManagement.deploy();

  console.log("BasicPortfolioManagement deployed to:", contract.address);
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
npx hardhat run scripts/deploy.js --network <network-name>
```

### 3. Test Suite

Use the following test suite to validate the contract:

```javascript
const { expect } = require("chai");

describe("BasicPortfolioManagement", function () {
  let Portfolio;
  let portfolio;
  let owner;
  let addr1;
  let addr2;
  let ERC20Mock;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy mock ERC20 token
    ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const token1 = await ERC20Mock.deploy("Token1", "TK1", owner.address, 100000);
    const token2 = await ERC20Mock.deploy("Token2", "TK2", owner.address, 100000);

    // Deploy Portfolio contract
    Portfolio = await ethers.getContractFactory("BasicPortfolioManagement");
    portfolio = await Portfolio.deploy();
    await portfolio.deployed();

    // Add assets to portfolio
    await portfolio.addAsset(token1.address, 6000); // 60%
    await portfolio.addAsset(token2.address, 4000); // 40%
  });

  it("Should correctly add and update assets", async function () {
    const asset1 = await portfolio.assets(0);
    const asset2 = await portfolio.assets(1);

    expect(asset1.token).to.equal(await ERC20Mock.address);
    expect(asset1.targetAllocation).to.equal(6000);

    await portfolio.updateAsset(asset1.token, 5000); // Update to 50%
    const updatedAsset = await portfolio.assets(0);
    expect(updatedAsset.targetAllocation).to.equal(5000);
  });

  it("Should allow investing and withdrawing ETH", async function () {
    await portfolio.connect(addr1).invest({ value: ethers.utils.parseEther("1.0") });
    expect(await portfolio.balances(addr1.address)).to.equal(ethers.utils.parseEther("1.0"));

    await portfolio.connect(addr1).withdraw(ethers.utils.parseEther("0.5"));
    expect(await portfolio.balances(addr1.address)).to.equal(ethers.utils.parseEther("0.5"));
  });
});
```

Run the test suite using:
```bash
npx hardhat test
```

### 4. Documentation

**API Documentation**:
- `addAsset(IERC20 _token, uint256 _targetAllocation)`: Adds a new asset to the portfolio with a specified target allocation.
- `updateAsset(IERC20 _token, uint256 _newTargetAllocation)`: Updates the target allocation of an existing asset.
- `invest()`: Allows users to invest ETH into the portfolio.
- `withdraw(uint256 _amount)`: Allows users to withdraw their investment.
- `rebalance()`: Rebalances the portfolio based on the predefined target allocations.
- `getAssetAllocation(IERC20 _token)`: Returns the target allocation of a specified asset.

**User Guide**:
- **Investing**: Call the `invest()` function, sending ETH along with the transaction.
- **Withdrawing**: Use the `withdraw(uint256 _amount)` function to withdraw ETH.
- **Rebalancing**: Only the owner can call `rebalance()` to adjust the portfolio.

**Developer Guide**:
- To extend the contract, you can add more functionality such as staking or governance by integrating additional libraries like OpenZeppelin.

### 5. Additional Deployment Instructions

- Use gas-efficient deployment options and batch processing for adding multiple assets.
- For real-world use, replace the mock ERC20 tokens with actual ones and adjust the rebalancing logic based on real market conditions.

This contract provides a robust starting point for managing tokenized portfolios using ERC20 tokens. Further customization can be added based on specific requirements.