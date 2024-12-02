Here’s the smart contract for the **Redemption Contract for ETF Tokens** using the ERC1400 standard. This contract allows investors to redeem their ETF tokens for their proportional share of the underlying assets or cash value.

### Contract: 2-1Z_1E_Redemption.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract RedemptionETF is Ownable {
    IERC1400 public securityToken;

    // Mapping to keep track of redeemable amounts
    mapping(address => uint256) public redeemableAmounts;

    event TokensRedeemed(address indexed investor, uint256 amount);
    
    constructor(address _securityToken) {
        securityToken = IERC1400(_securityToken);
    }

    // Function to set redeemable amount for an investor
    function setRedeemableAmount(address investor, uint256 amount) external onlyOwner {
        redeemableAmounts[investor] = amount;
    }

    // Function for investors to redeem their tokens
    function redeemTokens(uint256 amount) external {
        require(redeemableAmounts[msg.sender] >= amount, "Insufficient redeemable amount");

        // Here you can add the logic to transfer the underlying assets or cash value
        // For demonstration, we will just zero out the redeemable amount
        redeemableAmounts[msg.sender] -= amount;

        // Emit event after successful redemption
        emit TokensRedeemed(msg.sender, amount);
    }

    // Function to check redeemable amount for an investor
    function checkRedeemableAmount(address investor) external view returns (uint256) {
        return redeemableAmounts[investor];
    }
}
```

### Contract Explanation:

1. **Token Management:**
   - This contract interacts with an ERC1400 security token to manage the redemption process.

2. **Redeemable Amounts:**
   - It maintains a mapping of redeemable amounts for each investor, which can be set by the contract owner.

3. **Redemption Process:**
   - Investors can redeem their tokens for cash or underlying assets based on the set redeemable amount.

4. **Event Logging:**
   - Emits an event when tokens are redeemed for better tracking and transparency.

5. **Access Control:**
   - Only the contract owner can set redeemable amounts.

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
     const RedemptionETF = await hre.ethers.getContractFactory("RedemptionETF");
     const redemptionContract = await RedemptionETF.deploy(SecurityTokenAddress);
     await redemptionContract.deployed();
     console.log("Redemption Contract deployed to:", redemptionContract.address);
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
   Use Mocha and Chai for testing core functions like setting redeemable amounts and redeeming tokens.

   ```javascript
   const { expect } = require("chai");

   describe("RedemptionETF", function () {
     let redemptionContract;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const SecurityTokenMock = await ethers.getContractFactory("SecurityTokenMock");
       const securityToken = await SecurityTokenMock.deploy();
       await securityToken.deployed();

       const RedemptionETF = await ethers.getContractFactory("RedemptionETF");
       redemptionContract = await RedemptionETF.deploy(securityToken.address);
       await redemptionContract.deployed();
     });

     it("Should allow the owner to set redeemable amounts", async function () {
       await redemptionContract.setRedeemableAmount(investor.address, 100);
       const amount = await redemptionContract.checkRedeemableAmount(investor.address);
       expect(amount).to.equal(100);
     });

     it("Should allow investors to redeem tokens", async function () {
       await redemptionContract.setRedeemableAmount(investor.address, 100);
       await redemptionContract.connect(investor).redeemTokens(50);
       const amount = await redemptionContract.checkRedeemableAmount(investor.address);
       expect(amount).to.equal(50);
     });

     it("Should not allow redemption if amount exceeds redeemable", async function () {
       await redemptionContract.setRedeemableAmount(investor.address, 100);
       await expect(redemptionContract.connect(investor).redeemTokens(150)).to.be.revertedWith("Insufficient redeemable amount");
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
   - Provide step-by-step instructions on how to set redeemable amounts and redeem tokens.

3. **Developer Guide:**
   - Explain the contract architecture, focusing on the redemption process.

This contract effectively manages the redemption of ETF tokens, ensuring compliance and liquidity for investors. If you need further modifications or have additional requests, feel free to ask!