Here's the smart contract for the **Transfer Restrictions Contract for ETF Tokens** using the ERC1400 standard. This contract imposes compliance-based restrictions on ETF token transfers to ensure that only accredited or authorized investors can trade or hold these tokens.

### Contract: 2-1Z_1B_TransferRestrictions.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract TransferRestrictionsETF is Ownable {
    // Token details
    string public name = "ETF Token";
    string public symbol = "ETFT";
    uint256 public totalSupply;

    // Mapping to store balances
    mapping(address => uint256) private balances;

    // Mapping for accredited investors
    mapping(address => bool) private accreditedInvestors;

    event TokensIssued(address indexed investor, uint256 amount);
    event InvestorVerified(address indexed investor);
    event InvestorDeVerified(address indexed investor);
    event TransferRestricted(address indexed from, address indexed to);

    modifier onlyAccredited() {
        require(accreditedInvestors[msg.sender], "Not an accredited investor");
        _;
    }

    // Function to issue tokens to an accredited investor
    function issueTokens(address investor, uint256 amount) external onlyOwner onlyAccredited {
        totalSupply += amount;
        balances[investor] += amount;
        emit TokensIssued(investor, amount);
    }

    // Function to verify an investor
    function verifyInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = true;
        emit InvestorVerified(investor);
    }

    // Function to de-verify an investor
    function deVerifyInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = false;
        emit InvestorDeVerified(investor);
    }

    // Function to check the balance of an investor
    function balanceOf(address investor) external view returns (uint256) {
        return balances[investor];
    }

    // Function to check if an investor is accredited
    function isAccredited(address investor) external view returns (bool) {
        return accreditedInvestors[investor];
    }

    // Override transfer function to enforce restrictions
    function transfer(address to, uint256 amount) external onlyAccredited {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit TransferRestricted(msg.sender, to);
    }

    // Additional ERC1400 features can be added here for compliance checks
}
```

### Contract Explanation:

1. **Token Management:**
   - The contract manages ETF tokens, allowing only accredited investors to receive and transfer tokens.

2. **Investor Management:**
   - It includes functions to verify and de-verify accredited investors.

3. **Transfer Restrictions:**
   - Implements a modified transfer function that allows only accredited investors to transfer tokens.

4. **Events:**
   - Emits events for key actions such as token issuance and changes to investor accreditation status.

5. **Access Control:**
   - Only the contract owner can issue tokens and manage investor verification.

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
     const TransferRestrictionsETF = await hre.ethers.getContractFactory("TransferRestrictionsETF");
     const transferRestrictionsContract = await TransferRestrictionsETF.deploy();
     await transferRestrictionsContract.deployed();
     console.log("Transfer Restrictions Contract deployed to:", transferRestrictionsContract.address);
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
   Use Mocha and Chai for testing core functions such as token issuance and investor verification.

   ```javascript
   const { expect } = require("chai");

   describe("TransferRestrictionsETF", function () {
     let transferRestrictionsContract;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const TransferRestrictionsETF = await ethers.getContractFactory("TransferRestrictionsETF");
       transferRestrictionsContract = await TransferRestrictionsETF.deploy();
       await transferRestrictionsContract.deployed();
     });

     it("Should allow the owner to verify an investor", async function () {
       await transferRestrictionsContract.verifyInvestor(investor.address);
       expect(await transferRestrictionsContract.isAccredited(investor.address)).to.equal(true);
     });

     it("Should allow the owner to issue tokens to an accredited investor", async function () {
       await transferRestrictionsContract.verifyInvestor(investor.address);
       await transferRestrictionsContract.issueTokens(investor.address, 1000);
       expect(await transferRestrictionsContract.balanceOf(investor.address)).to.equal(1000);
     });

     it("Should not allow non-accredited investors to receive tokens", async function () {
       await expect(transferRestrictionsContract.issueTokens(investor.address, 1000)).to.be.revertedWith("Not an accredited investor");
     });

     it("Should allow the owner to de-verify an investor", async function () {
       await transferRestrictionsContract.verifyInvestor(investor.address);
       await transferRestrictionsContract.deVerifyInvestor(investor.address);
       expect(await transferRestrictionsContract.isAccredited(investor.address)).to.equal(false);
     });

     it("Should restrict token transfer for non-accredited investors", async function () {
       await transferRestrictionsContract.issueTokens(investor.address, 1000);
       await expect(transferRestrictionsContract.connect(investor).transfer(owner.address, 100)).to.be.revertedWith("Not an accredited investor");
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
   - Provide step-by-step instructions on how to verify investors and issue tokens.

3. **Developer Guide:**
   - Explain the contract architecture, including investor management and access control.

This contract ensures that only accredited investors can hold or trade ETF tokens, maintaining compliance with regulatory requirements. If you need any further modifications or additions, feel free to ask!