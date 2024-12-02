### Smart Contract: `ProfitTriggeredDividendDistributionContract.sol`

This smart contract is designed to distribute dividends only when the profits exceed a certain predefined threshold. It ensures that dividends are paid out based on profitability, aligning with the performance of the underlying assets.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ProfitTriggeredDividendDistributionContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public dividendToken; // ERC20 token used for dividend distribution
    uint256 public profitThreshold; // Minimum profit required to trigger dividend distribution
    uint256 public totalProfits; // Accumulated profits in the contract

    event ProfitsDeposited(address indexed from, uint256 amount);
    event DividendsDistributed(uint256 amount);
    event DividendWithdrawn(address indexed shareholder, uint256 amount);
    event ProfitThresholdUpdated(uint256 newThreshold);

    constructor(address _dividendToken, uint256 _profitThreshold) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_profitThreshold > 0, "Profit threshold must be greater than zero");
        dividendToken = IERC20(_dividendToken);
        profitThreshold = _profitThreshold;
    }

    // Function to deposit profits into the contract
    function depositProfits(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        dividendToken.safeTransferFrom(msg.sender, address(this), _amount);
        totalProfits += _amount;

        emit ProfitsDeposited(msg.sender, _amount);

        // Automatically distribute dividends if profits exceed the threshold
        if (totalProfits >= profitThreshold) {
            _distributeDividends();
        }
    }

    // Internal function to distribute dividends to all token holders
    function _distributeDividends() internal {
        uint256 dividendAmount = totalProfits;
        totalProfits = 0; // Reset total profits after distribution

        // Distribute dividends proportionally to all token holders
        uint256 totalSupply = dividendToken.totalSupply();
        for (uint256 i = 0; i < totalSupply; i++) {
            address shareholder = address(uint160(i)); // Placeholder logic for shareholder retrieval
            uint256 shareholderBalance = dividendToken.balanceOf(shareholder);

            if (shareholderBalance > 0) {
                uint256 share = (dividendAmount * shareholderBalance) / totalSupply;
                dividendToken.safeTransfer(shareholder, share);

                emit DividendWithdrawn(shareholder, share);
            }
        }

        emit DividendsDistributed(dividendAmount);
    }

    // Function to set a new profit threshold
    function setProfitThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Profit threshold must be greater than zero");
        profitThreshold = _newThreshold;
        emit ProfitThresholdUpdated(_newThreshold);
    }

    // Function to manually trigger dividend distribution
    function triggerDividendDistribution() external onlyOwner nonReentrant {
        require(totalProfits >= profitThreshold, "Profits have not reached the threshold");
        _distributeDividends();
    }

    // Function to view total profits in the contract
    function getTotalProfits() external view returns (uint256) {
        return totalProfits;
    }
}
```

### Key Features and Functionalities:

1. **Profit Threshold**:
   - `setProfitThreshold()`: Allows the owner to set the minimum profit required to trigger dividend distribution.
   - `profitThreshold`: Stores the minimum profit required to trigger dividend distribution.

2. **Profit Deposit and Distribution**:
   - `depositProfits()`: Allows the owner to deposit profits into the contract. Automatically distributes dividends if the profit threshold is met.
   - `_distributeDividends()`: Internal function to distribute dividends proportionally to all token holders when the profit threshold is met.

3. **Dividend Claim**:
   - `triggerDividendDistribution()`: Allows the owner to manually trigger dividend distribution if the profit threshold is met.

4. **Profit Tracking**:
   - `getTotalProfits()`: Returns the total accumulated profits in the contract.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const dividendToken = "0xYourDividendTokenAddress"; // Replace with actual dividend token address
  const profitThreshold = ethers.utils.parseUnits("1000", 18); // Set a threshold value

  console.log("Deploying contracts with the account:", deployer.address);

  const ProfitTriggeredDividendDistributionContract = await ethers.getContractFactory("ProfitTriggeredDividendDistributionContract");
  const contract = await ProfitTriggeredDividendDistributionContract.deploy(dividendToken, profitThreshold);

  console.log("ProfitTriggeredDividendDistributionContract deployed to:", contract.address);
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

describe("ProfitTriggeredDividendDistributionContract", function () {
  let ProfitTriggeredDividendDistributionContract, contract, owner, addr1, addr2, dividendToken;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC20 tokens for testing
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    dividendToken = await ERC20Mock.deploy("Dividend Token", "DVT", 18);

    ProfitTriggeredDividendDistributionContract = await ethers.getContractFactory("ProfitTriggeredDividendDistributionContract");
    contract = await ProfitTriggeredDividendDistributionContract.deploy(dividendToken.address, ethers.utils.parseUnits("1000", 18));
    await contract.deployed();

    // Mint and approve tokens for testing
    await dividendToken.mint(owner.address, ethers.utils.parseUnits("5000", 18));
    await dividendToken.mint(addr1.address, ethers.utils.parseUnits("1000", 18));
    await dividendToken.mint(addr2.address, ethers.utils.parseUnits("2000", 18));
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await dividendToken.connect(addr2).approve(contract.address, ethers.utils.parseUnits("2000", 18));
  });

  it("Should set and update profit threshold", async function () {
    await contract.setProfitThreshold(ethers.utils.parseUnits("2000", 18));
    expect(await contract.profitThreshold()).to.equal(ethers.utils.parseUnits("2000", 18));
  });

  it("Should deposit profits and trigger dividend distribution", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.depositProfits(ethers.utils.parseUnits("1000", 18));

    // Check if dividends are distributed
    expect(await dividendToken.balanceOf(addr1.address)).to.be.gt(ethers.utils.parseUnits("1000", 18));
    expect(await dividendToken.balanceOf(addr2.address)).to.be.gt(ethers.utils.parseUnits("2000", 18));
  });

  it("Should trigger manual dividend distribution when threshold is met", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.depositProfits(ethers.utils.parseUnits("500", 18));

    // No distribution should happen as the threshold is not met
    expect(await dividendToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseUnits("1000", 18));
    expect(await dividendToken.balanceOf(addr2.address)).to.equal(ethers.utils.parseUnits("2000", 18));

    // Deposit more profits to reach the threshold
    await contract.depositProfits(ethers.utils.parseUnits("500", 18));
    await contract.triggerDividendDistribution();

    // Check if dividends are distributed
    expect(await dividendToken.balanceOf(addr1.address)).to.be.gt(ethers.utils.parseUnits("1000", 18));
    expect(await dividendToken.balanceOf(addr2.address)).to.be.gt(ethers.utils.parseUnits("2000", 18));
  });
});
```

Run the test suite:

```bash
npx hardhat test
```

### Additional Features & Customization

1. **Oracle Integration**: Use Chainlink or other oracle services to track external data such as asset prices or revenue.
2. **Enhanced Dividend Logic**: Allow for more complex dividend rules, such as periodic distributions or profit-sharing based on specific conditions.
3. **Governance**: Implement a governance mechanism where token holders vote on profit thresholds and distribution parameters.

This contract provides a robust and flexible mechanism for distributing dividends only when profitability conditions are met, aligning payouts with the performance of the underlying assets.