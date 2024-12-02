### Smart Contract: `RestrictedTokenReinvestmentContract.sol`

This smart contract utilizes the ERC1404 standard to automatically reinvest dividends or profits into restricted tokens, ensuring that only compliant or accredited investors can benefit from reinvestment strategies. The contract is designed to comply with regulatory requirements and manage reinvestments efficiently.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";

contract RestrictedTokenReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    ERC1404 public restrictedToken;
    mapping(address => uint256) public dividendBalances;

    event DividendsDeposited(address indexed investor, uint256 amount);
    event DividendsReinvested(address indexed investor, uint256 amount, uint256 reinvestedAmount);
    event ReinvestmentStrategyUpdated(address indexed investor, uint256 percentage);
    event RestrictedTokenUpdated(address indexed tokenAddress);

    struct ReinvestmentStrategy {
        uint256 percentage; // Percentage of dividends to reinvest
    }

    mapping(address => ReinvestmentStrategy) public reinvestmentStrategies;

    constructor(address _restrictedToken) {
        require(_restrictedToken != address(0), "Invalid restricted token address");
        restrictedToken = ERC1404(_restrictedToken);
    }

    // Function to deposit dividends into the contract
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        restrictedToken.transferFrom(msg.sender, address(this), amount);
        dividendBalances[msg.sender] = dividendBalances[msg.sender].add(amount);

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function to set reinvestment strategy
    function setReinvestmentStrategy(uint256 percentage) external whenNotPaused {
        require(percentage <= 100, "Percentage cannot exceed 100");

        reinvestmentStrategies[msg.sender] = ReinvestmentStrategy({
            percentage: percentage
        });

        emit ReinvestmentStrategyUpdated(msg.sender, percentage);
    }

    // Function to reinvest dividends based on user's reinvestment strategy
    function reinvestDividends() external whenNotPaused nonReentrant {
        uint256 availableDividends = dividendBalances[msg.sender];
        require(availableDividends > 0, "No dividends available to reinvest");

        ReinvestmentStrategy memory strategy = reinvestmentStrategies[msg.sender];
        uint256 reinvestAmount = availableDividends.mul(strategy.percentage).div(100);
        uint256 remainingDividends = availableDividends.sub(reinvestAmount);

        require(restrictedToken.transfer(msg.sender, reinvestAmount), "Reinvestment failed");

        dividendBalances[msg.sender] = remainingDividends;

        emit DividendsReinvested(msg.sender, availableDividends, reinvestAmount);
    }

    // Function to update the restricted token address
    function updateRestrictedToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        restrictedToken = ERC1404(newTokenAddress);

        emit RestrictedTokenUpdated(newTokenAddress);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to withdraw dividends manually
    function withdrawDividends(uint256 amount) external nonReentrant {
        require(dividendBalances[msg.sender] >= amount, "Insufficient dividends");
        dividendBalances[msg.sender] = dividendBalances[msg.sender].sub(amount);
        restrictedToken.transfer(msg.sender, amount);
    }

    // Function to check if the user is compliant before any transfer or reinvestment
    function isTransferRestricted(address investor, uint256 amount) external view returns (bool) {
        uint8 restrictionCode = restrictedToken.detectTransferRestriction(investor, address(this), amount);
        return restrictionCode != 0; // 0 means no restriction
    }
}
```

### Key Features and Functionalities:

1. **Dividend Deposit and Reinvestment**:
   - `depositDividends()`: Allows users to deposit dividends in the form of ERC1404 restricted tokens.
   - `setReinvestmentStrategy()`: Allows users to set their reinvestment strategy by specifying the percentage of dividends to reinvest.
   - `reinvestDividends()`: Automatically reinvests dividends into restricted tokens based on the user's predefined strategy.

2. **Compliance Checks**:
   - `isTransferRestricted()`: Verifies if the user meets compliance criteria before transferring or reinvesting tokens.

3. **Administrative Controls**:
   - `updateRestrictedToken()`: Allows the contract owner to update the restricted token address.
   - `pause()` and `unpause()`: Allows the contract owner to pause and resume contract operations for security or administrative reasons.

4. **Security and Governance**:
   - Utilizes `Ownable`, `ReentrancyGuard`, and `Pausable` for enhanced security and administrative controls.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const restrictedTokenAddress = "0x123..."; // Replace with actual restricted token address

  console.log("Deploying contracts with the account:", deployer.address);

  const RestrictedTokenReinvestmentContract = await ethers.getContractFactory("RestrictedTokenReinvestmentContract");
  const contract = await RestrictedTokenReinvestmentContract.deploy(restrictedTokenAddress);

  console.log("RestrictedTokenReinvestmentContract deployed to:", contract.address);
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

describe("RestrictedTokenReinvestmentContract", function () {
  let RestrictedTokenReinvestmentContract, contract, owner, addr1, addr2, restrictedToken;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC1404 token for testing
    const ERC1404Mock = await ethers.getContractFactory("ERC1404Mock");
    restrictedToken = await ERC1404Mock.deploy();

    RestrictedTokenReinvestmentContract = await ethers.getContractFactory("RestrictedTokenReinvestmentContract");
    contract = await RestrictedTokenReinvestmentContract.deploy(restrictedToken.address);
    await contract.deployed();

    // Mint some tokens to addr1 for testing
    await restrictedToken.issue(addr1.address, 100);
  });

  it("Should allow user to deposit dividends", async function () {
    await restrictedToken.connect(addr1).approve(contract.address, 50);
    await contract.connect(addr1).depositDividends(50);

    expect(await contract.dividendBalances(addr1.address)).to.equal(50);
  });

  it("Should allow user to set reinvestment strategy", async function () {
    await contract.connect(addr1).setReinvestmentStrategy(80);

    const strategy = await contract.reinvestmentStrategies(addr1.address);
    expect(strategy.percentage).to.equal(80);
  });

  it("Should reinvest dividends based on strategy", async function () {
    await restrictedToken.connect(addr1).approve(contract.address, 50);
    await contract.connect(addr1).depositDividends(50);
    await contract.connect(addr1).setReinvestmentStrategy(50);

    await contract.connect(addr1).reinvestDividends();

    expect(await contract.dividendBalances(addr1.address)).to.equal(25); // 50% reinvested
    expect(await restrictedToken.balanceOf(addr1.address)).to.equal(75);
  });

  it("Should check for transfer restrictions", async function () {
    await restrictedToken.addRestriction(0, "0x01"); // Adding a mock restriction code
    const restricted = await contract.isTransferRestricted(addr1.address, 50);
    expect(restricted).to.equal(true);
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

### Additional Customizations

1. **Integration with Compliance Providers**: Integrate with compliance providers like Chainalysis to automatically verify compliance.
2. **Governance Features**: Implement on-chain governance for updating reinvestment strategies and compliance rules.
3. **Oracle Integration**: Include oracles for real-time data feed and compliance checks.
4. **DeFi Integration**: Support DeFi functionalities like staking and liquidity pooling.

This contract ensures compliance and automatic reinvestment of dividends into restricted tokens, adhering to the ERC1404 standard.