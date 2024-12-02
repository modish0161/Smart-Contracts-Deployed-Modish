### Smart Contract: `ProfitDrivenReinvestmentContract.sol`

This smart contract enables automatic reinvestment of profits or dividends from ERC20 tokens only when they exceed a predefined threshold. This ensures reinvestments are made only when substantial gains are realized, optimizing returns for users.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProfitDrivenReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // ERC20 token for reinvestment and dividend distribution
    IERC20 public investmentToken;
    IERC20 public dividendToken;

    // Minimum profit threshold for reinvestment
    uint256 public profitThreshold;

    // Mapping to store user dividend balances
    mapping(address => uint256) public userDividendBalances;

    // Event declarations
    event DividendsDeposited(address indexed user, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 reinvestedAmount, uint256 remainingAmount);
    event ProfitThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    // Constructor to initialize the contract with ERC20 tokens and a default profit threshold
    constructor(address _investmentToken, address _dividendToken, uint256 _profitThreshold) {
        require(_profitThreshold > 0, "Profit threshold must be greater than zero");
        investmentToken = IERC20(_investmentToken);
        dividendToken = IERC20(_dividendToken);
        profitThreshold = _profitThreshold;
    }

    // Function to deposit dividends
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        dividendToken.transferFrom(msg.sender, address(this), amount);
        userDividendBalances[msg.sender] = userDividendBalances[msg.sender].add(amount);

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function to reinvest profits if they exceed the profit threshold
    function reinvestProfits() external whenNotPaused nonReentrant {
        uint256 dividendBalance = userDividendBalances[msg.sender];
        require(dividendBalance >= profitThreshold, "Insufficient profit for reinvestment");

        // Reinvest the entire dividend balance into the investment token
        require(investmentToken.transfer(msg.sender, dividendBalance), "Reinvestment failed");

        emit ProfitsReinvested(msg.sender, dividendBalance, 0);

        // Reset user balance after reinvestment
        userDividendBalances[msg.sender] = 0;
    }

    // Function to update the profit threshold (admin only)
    function updateProfitThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be greater than zero");
        uint256 oldThreshold = profitThreshold;
        profitThreshold = newThreshold;

        emit ProfitThresholdUpdated(oldThreshold, newThreshold);
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
   - `reinvestProfits()`: Automatically reinvests profits when the user’s dividend balance exceeds the predefined threshold.

2. **Profit Threshold Management**:
   - `updateProfitThreshold()`: Allows the contract owner to update the profit threshold for reinvestments.

3. **Administrative Controls**:
   - `withdrawDividendTokens()`: Allows the contract owner to withdraw dividend tokens for administrative purposes.
   - `pause()` and `unpause()`: Allows the contract owner to pause and resume contract operations for security or administrative reasons.

### Deployment Scripts

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const investmentTokenAddress = "0x123..."; // Replace with actual token address
  const dividendTokenAddress = "0xabc..."; // Replace with actual token address
  const profitThreshold = ethers.utils.parseEther("10"); // 10 tokens threshold

  console.log("Deploying contracts with the account:", deployer.address);

  const ProfitDrivenReinvestmentContract = await ethers.getContractFactory("ProfitDrivenReinvestmentContract");
  const contract = await ProfitDrivenReinvestmentContract.deploy(investmentTokenAddress, dividendTokenAddress, profitThreshold);

  console.log("ProfitDrivenReinvestmentContract deployed to:", contract.address);
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

describe("ProfitDrivenReinvestmentContract", function () {
  let ProfitDrivenReinvestmentContract, contract, owner, addr1, investmentToken, dividendToken;
  const profitThreshold = ethers.utils.parseEther("10"); // 10 tokens threshold

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Mock ERC20 tokens for testing
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    investmentToken = await ERC20Mock.deploy("Investment Token", "INV", owner.address, ethers.utils.parseEther("1000"));
    dividendToken = await ERC20Mock.deploy("Dividend Token", "DIV", owner.address, ethers.utils.parseEther("1000"));

    ProfitDrivenReinvestmentContract = await ethers.getContractFactory("ProfitDrivenReinvestmentContract");
    contract = await ProfitDrivenReinvestmentContract.deploy(investmentToken.address, dividendToken.address, profitThreshold);
    await contract.deployed();

    // Transfer some dividend tokens to addr1 for testing
    await dividendToken.transfer(addr1.address, ethers.utils.parseEther("50"));
  });

  it("Should deposit dividends and update user balance", async function () {
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("20"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("20"));
    expect(await contract.userDividendBalances(addr1.address)).to.equal(ethers.utils.parseEther("20"));
  });

  it("Should reinvest profits if balance exceeds threshold", async function () {
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("20"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("20"));

    await investmentToken.mint(contract.address, ethers.utils.parseEther("20")); // Mint tokens to contract for testing

    await contract.connect(addr1).reinvestProfits();
    expect(await investmentToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("20")); // Reinvested 20 tokens
    expect(await contract.userDividendBalances(addr1.address)).to.equal(0); // Reset balance after reinvestment
  });

  it("Should not reinvest profits if balance is below threshold", async function () {
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("5"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("5"));

    await investmentToken.mint(contract.address, ethers.utils.parseEther("5")); // Mint tokens to contract for testing

    await expect(contract.connect(addr1).reinvestProfits()).to.be.revertedWith("Insufficient profit for reinvestment");
  });

  it("Should update the profit threshold", async function () {
    await contract.updateProfitThreshold(ethers.utils.parseEther("15")); // Update to 15 tokens
    expect(await contract.profitThreshold()).to.equal(ethers.utils.parseEther("15"));
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