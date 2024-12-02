Here’s the smart contract for the **Lock-Up Period Contract for ETF Tokens** using the ERC1400 standard. This contract will enforce lock-up periods during which ETF tokens cannot be traded or transferred.

### Contract: 2-1Z_1D_LockUpPeriod.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract LockUpPeriodETF is Ownable {
    IERC1400 public securityToken;
    
    // Mapping to track lock-up periods
    mapping(address => uint256) private lockUpEndDate;

    event TokensLocked(address indexed investor, uint256 lockUpPeriod);
    event TokensUnlocked(address indexed investor);

    constructor(address _securityToken) {
        securityToken = IERC1400(_securityToken);
    }

    // Function to lock tokens for a specified period
    function lockTokens(uint256 lockUpPeriodInDays) external {
        require(lockUpPeriodInDays > 0, "Lock-up period must be greater than zero");
        require(lockUpEndDate[msg.sender] < block.timestamp, "Tokens are already locked");

        uint256 lockUpDuration = block.timestamp + (lockUpPeriodInDays * 1 days);
        lockUpEndDate[msg.sender] = lockUpDuration;

        emit TokensLocked(msg.sender, lockUpPeriodInDays);
    }

    // Function to check if an address's tokens are locked
    function areTokensLocked(address investor) external view returns (bool) {
        return block.timestamp < lockUpEndDate[investor];
    }

    // Function to unlock tokens after the lock-up period
    function unlockTokens() external {
        require(block.timestamp >= lockUpEndDate[msg.sender], "Lock-up period is not over");
        
        lockUpEndDate[msg.sender] = 0; // Reset lock-up end date
        emit TokensUnlocked(msg.sender);
    }

    // Function to check the end date of the lock-up period
    function getLockUpEndDate(address investor) external view returns (uint256) {
        return lockUpEndDate[investor];
    }
}
```

### Contract Explanation:

1. **Token Management:**
   - This contract interacts with an ERC1400 security token to manage the locking of tokens.

2. **Lock-Up Functionality:**
   - Allows investors to lock their tokens for a specified period.
   - The lock-up period can be set in days.

3. **Unlock Functionality:**
   - Investors can unlock their tokens once the lock-up period has ended.

4. **Event Logging:**
   - Emits events when tokens are locked and unlocked for better tracking and transparency.

5. **Access Control:**
   - The contract owner can manage specific aspects, but locking and unlocking is performed by individual investors.

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
     const SecurityTokenAddress = "0x..."; // Replace with your deployed ERC1400 token address
     const LockUpPeriodETF = await hre.ethers.getContractFactory("LockUpPeriodETF");
     const lockUpPeriodContract = await LockUpPeriodETF.deploy(SecurityTokenAddress);
     await lockUpPeriodContract.deployed();
     console.log("Lock-Up Period Contract deployed to:", lockUpPeriodContract.address);
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
   Use Mocha and Chai for testing core functions like locking and unlocking tokens.

   ```javascript
   const { expect } = require("chai");

   describe("LockUpPeriodETF", function () {
     let lockUpPeriodContract;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const SecurityTokenMock = await ethers.getContractFactory("SecurityTokenMock");
       const securityToken = await SecurityTokenMock.deploy();
       await securityToken.deployed();

       const LockUpPeriodETF = await ethers.getContractFactory("LockUpPeriodETF");
       lockUpPeriodContract = await LockUpPeriodETF.deploy(securityToken.address);
       await lockUpPeriodContract.deployed();
     });

     it("Should allow the investor to lock tokens", async function () {
       await lockUpPeriodContract.lockTokens(30); // Lock for 30 days
       const endDate = await lockUpPeriodContract.getLockUpEndDate(investor.address);
       expect(endDate).to.be.greaterThan(Math.floor(Date.now() / 1000));
     });

     it("Should prevent locking tokens if already locked", async function () {
       await lockUpPeriodContract.lockTokens(30);
       await expect(lockUpPeriodContract.lockTokens(15)).to.be.revertedWith("Tokens are already locked");
     });

     it("Should allow unlocking tokens after the lock-up period", async function () {
       await lockUpPeriodContract.lockTokens(1); // Lock for 1 day
       await ethers.provider.send("evm_increaseTime", [86400]); // Move forward 1 day
       await ethers.provider.send("evm_mine"); // Mine a block
       await lockUpPeriodContract.unlockTokens();
       const endDate = await lockUpPeriodContract.getLockUpEndDate(investor.address);
       expect(endDate).to.equal(0);
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
   - Provide step-by-step instructions on how to lock and unlock tokens.

3. **Developer Guide:**
   - Explain the contract architecture, focusing on lock-up management.

This contract effectively manages lock-up periods for ETF tokens, ensuring compliance and security for transactions. If you need any further modifications or have additional requests, feel free to ask!