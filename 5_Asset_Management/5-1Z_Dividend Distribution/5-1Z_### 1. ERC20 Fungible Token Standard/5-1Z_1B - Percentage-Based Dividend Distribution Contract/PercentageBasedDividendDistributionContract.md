### Smart Contract: `PercentageBasedDividendDistributionContract.sol`

This smart contract is designed to distribute dividends based on predefined percentages for different classes of ERC20 tokens. It allows for customizable dividend allocations, ensuring that token holders receive their dividends according to the type of token they hold or the level of ownership they have.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PercentageBasedDividendDistributionContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public dividendToken; // ERC20 token used for dividend distribution
    mapping(address => uint256) public classPercentage; // Percentage allocation for each token class
    mapping(address => uint256) public totalDistributed; // Total dividends distributed per class

    event DividendsDeposited(address indexed from, uint256 amount);
    event DividendsAllocated(address indexed classToken, uint256 amount);
    event DividendWithdrawn(address indexed shareholder, address indexed classToken, uint256 amount);
    event ClassPercentageUpdated(address indexed classToken, uint256 percentage);

    constructor(address _dividendToken) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        dividendToken = IERC20(_dividendToken);
    }

    // Function to set the dividend percentage for each class of token
    function setClassPercentage(address classToken, uint256 percentage) external onlyOwner {
        require(classToken != address(0), "Invalid class token address");
        require(percentage > 0 && percentage <= 100, "Percentage must be between 1 and 100");
        classPercentage[classToken] = percentage;
        emit ClassPercentageUpdated(classToken, percentage);
    }

    // Function to deposit dividends into the contract for distribution
    function depositDividends(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        dividendToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit DividendsDeposited(msg.sender, _amount);
    }

    // Function to allocate dividends to each token class based on predefined percentages
    function allocateDividends(address[] calldata classTokens, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(address(this)) >= _amount, "Insufficient dividend balance");

        for (uint256 i = 0; i < classTokens.length; i++) {
            address classToken = classTokens[i];
            uint256 percentage = classPercentage[classToken];
            require(percentage > 0, "Class percentage not set");

            uint256 classDividend = _amount * percentage / 100;
            totalDistributed[classToken] += classDividend;

            emit DividendsAllocated(classToken, classDividend);
        }
    }

    // Function for shareholders to claim their dividends
    function claimDividends(address classToken) external nonReentrant {
        require(classPercentage[classToken] > 0, "Invalid class token or no dividends allocated");

        IERC20 classERC20 = IERC20(classToken);
        uint256 userBalance = classERC20.balanceOf(msg.sender);
        require(userBalance > 0, "No class tokens held");

        uint256 userShare = totalDistributed[classToken] * userBalance / classERC20.totalSupply();
        require(userShare > 0, "No dividends to claim");

        dividendToken.safeTransfer(msg.sender, userShare);
        totalDistributed[classToken] -= userShare;

        emit DividendWithdrawn(msg.sender, classToken, userShare);
    }

    // Function to view the total dividends distributed for a specific class token
    function getTotalDistributed(address classToken) external view returns (uint256) {
        return totalDistributed[classToken];
    }
}
```

### Key Features and Functionalities:

1. **Dividend Allocation**:
   - `setClassPercentage()`: Sets the dividend percentage for each token class.
   - `depositDividends()`: Deposits dividends into the contract for distribution.
   - `allocateDividends()`: Allocates dividends to each token class based on predefined percentages.

2. **Dividend Claim**:
   - `claimDividends()`: Allows shareholders to claim their dividends based on the class of tokens they hold.

3. **Administrative Functions**:
   - `setClassPercentage()`: Updates the dividend allocation percentage for a given class of token.
   - `getTotalDistributed()`: Retrieves the total amount of dividends distributed to a particular token class.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const dividendToken = "0xYourDividendTokenAddress"; // Replace with actual dividend token address

  console.log("Deploying contracts with the account:", deployer.address);

  const PercentageBasedDividendDistributionContract = await ethers.getContractFactory("PercentageBasedDividendDistributionContract");
  const contract = await PercentageBasedDividendDistributionContract.deploy(dividendToken);

  console.log("PercentageBasedDividendDistributionContract deployed to:", contract.address);
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

describe("PercentageBasedDividendDistributionContract", function () {
  let PercentageBasedDividendDistributionContract, contract, owner, addr1, dividendToken, classTokenA, classTokenB;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Mock ERC20 tokens for testing
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    dividendToken = await ERC20Mock.deploy("Dividend Token", "DVT", 18);
    classTokenA = await ERC20Mock.deploy("Class Token A", "CTA", 18);
    classTokenB = await ERC20Mock.deploy("Class Token B", "CTB", 18);

    PercentageBasedDividendDistributionContract = await ethers.getContractFactory("PercentageBasedDividendDistributionContract");
    contract = await PercentageBasedDividendDistributionContract.deploy(dividendToken.address);
    await contract.deployed();

    // Mint and approve tokens for testing
    await dividendToken.mint(owner.address, 1000);
    await classTokenA.mint(owner.address, 1000);
    await classTokenA.transfer(addr1.address, 500);
    await classTokenB.mint(owner.address, 500);
  });

  it("Should set class percentage", async function () {
    await contract.setClassPercentage(classTokenA.address, 60);
    await contract.setClassPercentage(classTokenB.address, 40);
    expect(await contract.classPercentage(classTokenA.address)).to.equal(60);
    expect(await contract.classPercentage(classTokenB.address)).to.equal(40);
  });

  it("Should deposit dividends", async function () {
    await dividendToken.approve(contract.address, 500);
    await contract.depositDividends(500);
    expect(await dividendToken.balanceOf(contract.address)).to.equal(500);
  });

  it("Should allocate dividends based on class percentage", async function () {
    await contract.setClassPercentage(classTokenA.address, 60);
    await contract.setClassPercentage(classTokenB.address, 40);

    await dividendToken.approve(contract.address, 500);
    await contract.depositDividends(500);

    await contract.allocateDividends([classTokenA.address, classTokenB.address], 500);

    expect(await contract.getTotalDistributed(classTokenA.address)).to.equal(300);
    expect(await contract.getTotalDistributed(classTokenB.address)).to.equal(200);
  });

  it("Should allow shareholders to claim dividends", async function () {
    await contract.setClassPercentage(classTokenA.address, 60);

    await dividendToken.approve(contract.address, 500);
    await contract.depositDividends(500);

    await contract.allocateDividends([classTokenA.address], 500);
    await contract.connect(addr1).claimDividends(classTokenA.address);

    expect(await dividendToken.balanceOf(addr1.address)).to.equal(150); // 500 (shares) / 1000 (total) * 300 (total allocated)
  });
});
```

Run the test suite:

```bash
npx hardhat test
```

This contract allows for customized dividend distribution based on predefined percentages for each token class, ensuring that all dividends are allocated accurately according to the specified allocation.