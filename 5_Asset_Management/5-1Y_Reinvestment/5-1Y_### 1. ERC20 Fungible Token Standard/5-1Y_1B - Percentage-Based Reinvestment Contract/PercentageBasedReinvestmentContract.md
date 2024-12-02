### Smart Contract: `PercentageBasedReinvestmentContract.sol`

This smart contract enables users to automatically reinvest a specified percentage of profits or dividends from ERC20 tokens, while allowing them to withdraw or save the remaining portion. It provides flexibility in managing reinvestment strategies and compounding returns.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PercentageBasedReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // ERC20 token for reinvestment and dividend distribution
    IERC20 public investmentToken;
    IERC20 public dividendToken;

    // Minimum reinvestment percentage (in basis points, where 100% = 10000)
    uint256 public minimumReinvestmentPercentage;

    // Mapping to store user reinvestment percentages
    mapping(address => uint256) public userReinvestmentPercentages;

    // Mapping to store user dividend balances
    mapping(address => uint256) public userDividendBalances;

    // Event declarations
    event DividendsDeposited(address indexed user, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 reinvestedAmount, uint256 withdrawnAmount);
    event ReinvestmentPercentageUpdated(address indexed user, uint256 oldPercentage, uint256 newPercentage);

    // Constructor to initialize the contract with ERC20 tokens and a default minimum reinvestment percentage
    constructor(address _investmentToken, address _dividendToken, uint256 _minimumReinvestmentPercentage) {
        require(_minimumReinvestmentPercentage <= 10000, "Percentage cannot exceed 100%");
        investmentToken = IERC20(_investmentToken);
        dividendToken = IERC20(_dividendToken);
        minimumReinvestmentPercentage = _minimumReinvestmentPercentage;
    }

    // Function to deposit dividends
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        dividendToken.transferFrom(msg.sender, address(this), amount);
        userDividendBalances[msg.sender] = userDividendBalances[msg.sender].add(amount);

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function to set user reinvestment percentage
    function setReinvestmentPercentage(uint256 percentage) external whenNotPaused {
        require(percentage >= minimumReinvestmentPercentage, "Percentage below minimum");
        require(percentage <= 10000, "Percentage cannot exceed 100%");
        
        uint256 oldPercentage = userReinvestmentPercentages[msg.sender];
        userReinvestmentPercentages[msg.sender] = percentage;

        emit ReinvestmentPercentageUpdated(msg.sender, oldPercentage, percentage);
    }

    // Function to reinvest profits and withdraw the remaining amount
    function reinvestProfits() external whenNotPaused nonReentrant {
        uint256 dividendBalance = userDividendBalances[msg.sender];
        require(dividendBalance > 0, "No dividends to reinvest");

        uint256 reinvestmentPercentage = userReinvestmentPercentages[msg.sender];
        uint256 reinvestedAmount = dividendBalance.mul(reinvestmentPercentage).div(10000);
        uint256 withdrawnAmount = dividendBalance.sub(reinvestedAmount);

        // Transfer reinvested tokens to user
        require(investmentToken.transfer(msg.sender, reinvestedAmount), "Investment token transfer failed");

        // Transfer withdrawn dividends to user
        require(dividendToken.transfer(msg.sender, withdrawnAmount), "Dividend token transfer failed");

        // Update user balance
        userDividendBalances[msg.sender] = 0;

        emit ProfitsReinvested(msg.sender, reinvestedAmount, withdrawnAmount);
    }

    // Function to update the minimum reinvestment percentage (admin only)
    function updateMinimumReinvestmentPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 10000, "Percentage cannot exceed 100%");
        minimumReinvestmentPercentage = newPercentage;
    }

    // Function to withdraw dividend tokens (admin only)
    function withdrawDividendTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.transfer(owner(), amount), "Withdrawal failed");
    }

    // Function to pause the contract (admin only)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (admin only)
    function unpause() external onlyOwner {
        _unpause();
    }
}
```

### Key Features and Functionalities:

1. **Dividend Deposit and Reinvestment**:
   - `depositDividends()`: Allows users to deposit dividends in the form of ERC20 tokens.
   - `reinvestProfits()`: Reinvests a percentage of dividends into the investment token and withdraws the remaining amount based on user preferences.

2. **Reinvestment Percentages**:
   - `setReinvestmentPercentage()`: Allows users to set their desired reinvestment percentage, which must be above the minimum threshold set by the contract owner.

3. **Administrative Controls**:
   - `updateMinimumReinvestmentPercentage()`: Allows the contract owner to set a new minimum reinvestment percentage for all users.
   - `withdrawDividendTokens()`: Allows the contract owner to withdraw dividend tokens for administrative purposes.

4. **Emergency Controls**:
   - `pause()` and `unpause()`: Allows the contract owner to pause and resume contract operations for security or administrative reasons.

### Deployment Scripts

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const investmentTokenAddress = "0x123..."; // Replace with actual token address
  const dividendTokenAddress = "0xabc..."; // Replace with actual token address
  const minimumReinvestmentPercentage = 5000; // 50% minimum reinvestment

  console.log("Deploying contracts with the account:", deployer.address);

  const PercentageBasedReinvestmentContract = await ethers.getContractFactory("PercentageBasedReinvestmentContract");
  const contract = await PercentageBasedReinvestmentContract.deploy(investmentTokenAddress, dividendTokenAddress, minimumReinvestmentPercentage);

  console.log("PercentageBasedReinvestmentContract deployed to:", contract.address);
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

describe("PercentageBasedReinvestmentContract", function () {
  let PercentageBasedReinvestmentContract, contract, owner, addr1, investmentToken, dividendToken;
  const minimumReinvestmentPercentage = 5000; // 50%

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Mock ERC20 tokens for testing
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    investmentToken = await ERC20Mock.deploy("Investment Token", "INV", owner.address, ethers.utils.parseEther("1000"));
    dividendToken = await ERC20Mock.deploy("Dividend Token", "DIV", owner.address, ethers.utils.parseEther("1000"));

    PercentageBasedReinvestmentContract = await ethers.getContractFactory("PercentageBasedReinvestmentContract");
    contract = await PercentageBasedReinvestmentContract.deploy(investmentToken.address, dividendToken.address, minimumReinvestmentPercentage);
    await contract.deployed();

    // Transfer some dividend tokens to addr1 for testing
    await dividendToken.transfer(addr1.address, ethers.utils.parseEther("50"));
  });

  it("Should deposit dividends and update user balance", async function () {
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("20"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("20"));
    expect(await contract.userDividendBalances(addr1.address)).to.equal(ethers.utils.parseEther("20"));
  });

  it("Should set and update reinvestment percentage", async function () {
    await contract.connect(addr1).setReinvestmentPercentage(6000); // 60%
    expect(await contract.userReinvestmentPercentages(addr1.address)).to.equal(6000);
  });

  it("Should reinvest profits and withdraw the remaining amount", async function () {
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("20"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("20"));

    await contract.connect(addr1).setReinvestmentPercentage(6000); // 60%
    await investmentToken.mint(contract.address, ethers.utils.parseEther("20")); // Mint tokens to contract for testing

    await contract.connect(addr1).reinvestProfits();
    expect(await investmentToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("12")); // 60% of 20
    expect(await dividendToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("8")); // 40% of 20
  });

  it("Should not set reinvestment percentage below minimum", async function () {
    await expect(contract.connect(addr1).setReinvestmentPercentage(4000)).to.be.revertedWith("Percentage below minimum");
  });

  it("Should update the minimum reinvestment percentage", async function () {
    await contract.updateMinimumReinvestmentPercentage(4000); // 40%
    expect(await contract.minimumReinvestmentPercentage()).to.equal(

4000);
  });

  it("Should pause and unpause the contract", async function () {
    await contract.pause();
    await expect(contract.connect(addr1).depositDividends(ethers.utils.parseEther("10"))).to.be.revertedWith("Pausable: paused");

    await contract.unpause();
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("10"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("10"));
    expect(await contract.userDividendBalances(addr1.address)).to.equal(ethers.utils.parseEther("10"));
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

This script will deploy the contract, verify its functionality through unit tests, and ensure that the logic behaves as expected. If needed, further customization and features can be added based on specific requirements.