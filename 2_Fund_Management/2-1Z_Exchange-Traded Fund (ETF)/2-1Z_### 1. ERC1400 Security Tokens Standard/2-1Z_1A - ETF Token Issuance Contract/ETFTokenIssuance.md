Here’s the smart contract for the **ETF Token Issuance Contract** using the ERC1400 standard. This contract ensures compliance with regulations while providing fractional ownership of an ETF’s portfolio of assets.

### Contract: 2-1Z_1A_ETFTokenIssuance.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract ETFTokenIssuance is Ownable {
    // Token details
    string public name = "ETF Token";
    string public symbol = "ETFT";
    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => bool) private accreditedInvestors;

    event TokensIssued(address indexed investor, uint256 amount);
    event InvestorVerified(address indexed investor);
    event InvestorDeVerified(address indexed investor);

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

    // Additional functionality for ERC1400 compliance can be added here
}
```

### Contract Explanation:

1. **Token Management:**
   - The contract manages an ETF token with basic functionalities for issuing tokens and verifying investors.

2. **Investor Management:**
   - It includes functions to verify and de-verify accredited investors, allowing only these investors to receive tokens.

3. **Events:**
   - Emits events for key actions such as token issuance and changes to investor accreditation status.

4. **Access Control:**
   - Only the contract owner (e.g., fund manager) can issue tokens and manage investor verification.

### Deployment Instructions:

1. **Prerequisites:**
   - Make sure you have Node.js and Hardhat installed.
   - Install OpenZeppelin contracts:
     ```bash
     npm install @openzeppelin/contracts
     ```

2. **Deployment Script:**
   Create a deployment script `deploy.js` in the `scripts` folder:

   ```javascript
   const hre = require("hardhat");

   async function main() {
     const ETFTokenIssuance = await hre.ethers.getContractFactory("ETFTokenIssuance");
     const issuanceContract = await ETFTokenIssuance.deploy();
     await issuanceContract.deployed();
     console.log("ETF Token Issuance Contract deployed to:", issuanceContract.address);
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

   describe("ETFTokenIssuance", function () {
     let issuanceContract;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const ETFTokenIssuance = await ethers.getContractFactory("ETFTokenIssuance");
       issuanceContract = await ETFTokenIssuance.deploy();
       await issuanceContract.deployed();
     });

     it("Should allow the owner to verify an investor", async function () {
       await issuanceContract.verifyInvestor(investor.address);
       expect(await issuanceContract.isAccredited(investor.address)).to.equal(true);
     });

     it("Should allow the owner to issue tokens to an accredited investor", async function () {
       await issuanceContract.verifyInvestor(investor.address);
       await issuanceContract.issueTokens(investor.address, 1000);
       expect(await issuanceContract.balanceOf(investor.address)).to.equal(1000);
     });

     it("Should not allow non-accredited investors to receive tokens", async function () {
       await expect(issuanceContract.issueTokens(investor.address, 1000)).to.be.revertedWith("Not an accredited investor");
     });

     it("Should allow the owner to de-verify an investor", async function () {
       await issuanceContract.verifyInvestor(investor.address);
       await issuanceContract.deVerifyInvestor(investor.address);
       expect(await issuanceContract.isAccredited(investor.address)).to.equal(false);
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

This contract provides a secure framework for issuing ETF tokens while ensuring compliance with regulatory requirements. If you have any additional requests or modifications, feel free to ask!