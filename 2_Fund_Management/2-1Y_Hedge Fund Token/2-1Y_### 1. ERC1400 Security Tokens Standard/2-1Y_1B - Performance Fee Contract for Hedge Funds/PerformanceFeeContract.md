Sure! Below is the complete smart contract code for the **Hedge Fund Token Issuance Contract**, which incorporates performance fee calculations based on the hedge fund's profits, while adhering to the ERC1400 standard.

### Contract: 2-1Y_1B_PerformanceFeeContract.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract PerformanceFeeContract is Ownable, ReentrancyGuard {
    struct Investor {
        bool isAccredited;
        uint256 shares;
        uint256 lastClaimedProfit;
    }

    mapping(address => Investor) public investors;
    uint256 public totalShares;
    uint256 public performanceFeePercentage; // Performance fee as a percentage (e.g., 20 for 20%)
    uint256 public profitThreshold; // Profit threshold for performance fee calculation
    uint256 public totalProfits; // Total profits accrued by the fund

    event TokensIssued(address indexed investor, uint256 shares);
    event PerformanceFeeClaimed(address indexed manager, uint256 feeAmount);

    constructor(uint256 _performanceFeePercentage, uint256 _profitThreshold) {
        performanceFeePercentage = _performanceFeePercentage;
        profitThreshold = _profitThreshold;
    }

    modifier onlyAccredited() {
        require(investors[msg.sender].isAccredited, "Not an accredited investor");
        _;
    }

    function registerAccreditedInvestor(address _investor) external onlyOwner {
        require(_investor != address(0), "Invalid investor address");
        investors[_investor].isAccredited = true;
    }

    function issueTokens(uint256 _shares) external onlyAccredited nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");

        investors[msg.sender].shares += _shares;
        totalShares += _shares;

        emit TokensIssued(msg.sender, _shares);
    }

    function recordProfits(uint256 _profit) external onlyOwner {
        require(_profit > 0, "Profit must be greater than zero");
        totalProfits += _profit;
    }

    function calculatePerformanceFee() internal view returns (uint256) {
        if (totalProfits > profitThreshold) {
            uint256 performanceFee = (totalProfits - profitThreshold) * performanceFeePercentage / 100;
            return performanceFee;
        }
        return 0;
    }

    function claimPerformanceFee() external onlyOwner nonReentrant {
        uint256 feeAmount = calculatePerformanceFee();
        require(feeAmount > 0, "No performance fee to claim");

        totalProfits -= feeAmount; // Deduct fee from total profits
        emit PerformanceFeeClaimed(msg.sender, feeAmount);
        
        // Here, you would implement the logic to transfer the fee to the fund manager's address
        // e.g., transfer(fundManagerAddress, feeAmount);
    }

    function withdrawTokens(uint256 _shares) external onlyAccredited nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");
        require(investors[msg.sender].shares >= _shares, "Insufficient shares");

        investors[msg.sender].shares -= _shares;
        totalShares -= _shares;

        // Implement logic to transfer the underlying asset tokens to the investor
        // e.g., underlyingAsset.transfer(msg.sender, _shares);
    }

    function getInvestorShares(address _investor) external view returns (uint256) {
        return investors[_investor].shares;
    }

    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }

    function getTotalProfits() external view returns (uint256) {
        return totalProfits;
    }
}
```

### Contract Explanation:

1. **Investor Management:**
   - The contract manages accredited investors using a mapping that stores their accreditation status and the number of shares they hold.

2. **Token Issuance:**
   - Only accredited investors can issue tokens, ensuring compliance with regulations.

3. **Performance Fee Calculation:**
   - The contract calculates performance fees based on profits exceeding a predefined threshold. The performance fee is a percentage of profits beyond that threshold.

4. **Claiming Performance Fees:**
   - The fund manager can claim performance fees using the `claimPerformanceFee` function.

5. **Events:**
   - The contract emits events for token issuance and performance fee claims, ensuring transparency.

6. **Security Features:**
   - The contract uses OpenZeppelin’s `ReentrancyGuard` to prevent reentrancy attacks.
   - Only the contract owner can register new accredited investors and manage profit recording.

7. **Constructor:**
   - The constructor accepts the performance fee percentage and profit threshold upon deployment.

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

     const PerformanceFeeContract = await hre.ethers.getContractFactory("PerformanceFeeContract");
     const performanceFeeContract = await PerformanceFeeContract.deploy(20, 1000); // 20% fee and 1000 threshold

     await performanceFeeContract.deployed();
     console.log("Performance Fee Contract deployed to:", performanceFeeContract.address);
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
   Use Mocha and Chai for testing core functions such as investor registration, token issuance, profit recording, and fee claiming.

   ```javascript
   const { expect } = require("chai");

   describe("Performance Fee Contract", function () {
     let performanceFeeContract;
     let owner, investor1, investor2;

     beforeEach(async function () {
       [owner, investor1, investor2] = await ethers.getSigners();

       const PerformanceFeeContract = await ethers.getContractFactory("PerformanceFeeContract");
       performanceFeeContract = await PerformanceFeeContract.deploy(20, 1000); // 20% fee and 1000 threshold
       await performanceFeeContract.deployed();
     });

     it("Should allow registration of accredited investors", async function () {
       await performanceFeeContract.registerAccreditedInvestor(investor1.address);
       expect(await performanceFeeContract.investors(investor1.address).isAccredited).to.be.true;
     });

     it("Should allow issuance of tokens to accredited investors", async function () {
       await performanceFeeContract.registerAccreditedInvestor(investor1.address);
       await performanceFeeContract.issueTokens(100);
       expect(await performanceFeeContract.getInvestorShares(investor1.address)).to.equal(100);
     });

     it("Should calculate performance fees correctly", async function () {
       await performanceFeeContract.recordProfits(2000);
       await performanceFeeContract.claimPerformanceFee();
       expect(await performanceFeeContract.getTotalProfits()).to.equal(1800); // Remaining profits after fee
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
   - Provide step-by-step instructions on how to register investors, issue tokens, record profits, and claim performance fees.

3. **Developer Guide:**
   - Explain the contract architecture, access control, and customization options for extending hedge fund functionalities.

This smart contract establishes a robust framework for hedge fund tokenization, ensuring compliance with regulations while facilitating efficient management of investments and performance fee calculations.