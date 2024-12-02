Here's a complete smart contract for the **Performance Fee Distribution Contract for ERC20 Hedge Fund Tokens**. This contract automatically calculates and distributes performance fees to fund managers based on the profits generated by the hedge fund.

### Contract: 2-1Y_3B_PerformanceFeeDistribution.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PerformanceFeeDistribution is ERC20, Ownable, ReentrancyGuard {
    uint256 public performanceFeePercentage; // Performance fee in basis points (1/100th of a percent)
    mapping(address => uint256) public profits; // Profits generated for each address
    mapping(address => uint256) public performanceFees; // Accumulated performance fees for each address

    event PerformanceFeeDistributed(address indexed manager, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 _performanceFeePercentage)
        ERC20(name, symbol) {
        performanceFeePercentage = _performanceFeePercentage;
    }

    modifier onlyManager() {
        require(msg.sender == owner(), "Only fund manager can call this function");
        _;
    }

    function recordProfit(address investor, uint256 profitAmount) external onlyManager {
        require(profitAmount > 0, "Profit amount must be greater than 0");
        profits[investor] += profitAmount;
    }

    function distributePerformanceFee(address manager) external onlyManager nonReentrant {
        uint256 totalProfits = profits[manager];
        require(totalProfits > 0, "No profits to distribute");

        uint256 feeAmount = (totalProfits * performanceFeePercentage) / 10000; // Calculate fee based on the performance fee percentage
        require(feeAmount > 0, "No performance fee to distribute");

        // Reset profits for the manager
        profits[manager] = 0;
        performanceFees[manager] += feeAmount;

        // Transfer the performance fee from the contract to the manager
        _mint(manager, feeAmount);
        emit PerformanceFeeDistributed(manager, feeAmount);
    }

    function withdrawPerformanceFees() external nonReentrant {
        uint256 feeAmount = performanceFees[msg.sender];
        require(feeAmount > 0, "No performance fees to withdraw");

        performanceFees[msg.sender] = 0; // Reset fee amount for the caller
        _mint(msg.sender, feeAmount); // Mint new tokens to the manager
    }
}
```

### Contract Explanation:

1. **Token Management:**
   - The contract inherits from OpenZeppelin's `ERC20`, allowing it to manage fungible tokens.

2. **Performance Fee Calculation:**
   - The contract maintains a record of profits generated for each investor.
   - Performance fees are calculated as a percentage of the profits.

3. **Fee Distribution:**
   - The `distributePerformanceFee` function allows fund managers to distribute fees based on the profits they manage.
   - It mints new tokens representing the performance fee and assigns them to the manager.

4. **Withdrawal:**
   - Managers can withdraw their accumulated performance fees using the `withdrawPerformanceFees` function.

5. **Events:**
   - Emits events when performance fees are distributed for tracking purposes.

### Deployment Instructions:

1. **Prerequisites:**
   - Ensure you have Node.js and Hardhat installed.
   - Install OpenZeppelin contracts:
     ```bash
     npm install @openzeppelin/contracts
     ```

2. **Deployment Script:**
   Create a deployment script `deploy.js` in the `scripts` folder:

   ```javascript
   const hre = require("hardhat");

   async function main() {
     const [deployer] = await hre.ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const PerformanceFeeDistribution = await hre.ethers.getContractFactory("PerformanceFeeDistribution");
     const token = await PerformanceFeeDistribution.deploy("Hedge Fund Token", "HFT", 20); // 20% performance fee

     await token.deployed();
     console.log("Performance Fee Distribution Contract deployed to:", token.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

3. **Run the Deployment Script:**
   ```bash
   npx hardhat run scripts/deploy.js --network [network-name]
   ```

### Testing Suite:

1. **Basic Tests:**
   Use Mocha and Chai for testing core functions such as recording profits and distributing performance fees.

   ```javascript
   const { expect } = require("chai");

   describe("Performance Fee Distribution", function () {
     let contract;
     let owner, manager, investor;

     beforeEach(async function () {
       [owner, manager, investor] = await ethers.getSigners();

       const PerformanceFeeDistribution = await ethers.getContractFactory("PerformanceFeeDistribution");
       contract = await PerformanceFeeDistribution.deploy("Hedge Fund Token", "HFT", 20);
       await contract.deployed();
     });

     it("Should allow the manager to record profits", async function () {
       await contract.connect(manager).recordProfit(investor.address, 100);
       expect(await contract.profits(investor.address)).to.equal(100);
     });

     it("Should distribute performance fees correctly", async function () {
       await contract.connect(manager).recordProfit(investor.address, 100);
       await contract.connect(manager).distributePerformanceFee(manager.address);
       expect(await contract.balanceOf(manager.address)).to.equal(20); // 20% of 100
     });

     it("Should allow the manager to withdraw performance fees", async function () {
       await contract.connect(manager).recordProfit(investor.address, 100);
       await contract.connect(manager).distributePerformanceFee(manager.address);
       await contract.connect(manager).withdrawPerformanceFees();
       expect(await contract.balanceOf(manager.address)).to.equal(20);
     });
   });
   ```

2. **Run Tests:**
   ```bash
   npx hardhat test
   ```

### Documentation:

1. **API Documentation:**
   - Include detailed NatSpec comments for each function, event, and modifier in the contract.

2. **User Guide:**
   - Provide step-by-step instructions on how to manage performance fee distributions.

3. **Developer Guide:**
   - Explain the contract architecture, including how performance fees are calculated and managed.

This smart contract provides a framework for managing performance fees in a hedge fund context, enabling efficient and compliant operations. Let me know if you need any modifications or additional features!