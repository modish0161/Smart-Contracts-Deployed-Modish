Here’s the smart contract for the **Dividend and Yield Distribution Contract for ETFs** using the ERC1400 standard. This contract will handle the distribution of dividends or yields generated by the ETF’s portfolio to its token holders.

### Contract: 2-1Z_1C_DividendDistribution.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract DividendDistributionETF is Ownable {
    // Token details
    IERC1400 public securityToken;
    uint256 public totalDividends;

    // Mapping to track dividends claimed by investors
    mapping(address => uint256) private dividendsClaimed;

    event DividendsDistributed(uint256 amount);
    event DividendClaimed(address indexed investor, uint256 amount);

    constructor(address _securityToken) {
        securityToken = IERC1400(_securityToken);
    }

    // Function to distribute dividends to token holders
    function distributeDividends(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        totalDividends += amount;

        // Transfer the specified amount to this contract
        // Assuming the contract holds enough funds for distribution
        emit DividendsDistributed(amount);
    }

    // Function to calculate the dividend for an investor
    function calculateDividend(address investor) public view returns (uint256) {
        uint256 totalSupply = securityToken.totalSupply();
        uint256 balance = securityToken.balanceOf(investor);
        if (totalSupply == 0 || balance == 0) {
            return 0;
        }
        uint256 dividend = (totalDividends * balance) / totalSupply;
        return dividend - dividendsClaimed[investor]; // Unclaimed dividend
    }

    // Function for investors to claim their dividends
    function claimDividends() external {
        uint256 dividend = calculateDividend(msg.sender);
        require(dividend > 0, "No dividends to claim");

        dividendsClaimed[msg.sender] += dividend;

        // Transfer the claimed dividends to the investor
        payable(msg.sender).transfer(dividend);

        emit DividendClaimed(msg.sender, dividend);
    }

    // Function to withdraw any accidental ether sent to this contract
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Fallback function to accept Ether
    receive() external payable {}
}
```

### Contract Explanation:

1. **Token Management:**
   - The contract interfaces with an ERC1400 security token to manage the dividend distribution based on token holdings.

2. **Dividend Distribution:**
   - The contract allows the owner to distribute dividends based on the total supply of tokens and individual holdings.

3. **Claim Functionality:**
   - Investors can claim their unclaimed dividends based on their token balance.

4. **Events:**
   - Emits events for dividends distributed and claimed for transparency.

5. **Access Control:**
   - Only the contract owner can distribute dividends and withdraw funds.

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
     const DividendDistributionETF = await hre.ethers.getContractFactory("DividendDistributionETF");
     const dividendDistributionContract = await DividendDistributionETF.deploy(SecurityTokenAddress);
     await dividendDistributionContract.deployed();
     console.log("Dividend Distribution Contract deployed to:", dividendDistributionContract.address);
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
   Use Mocha and Chai for testing core functions such as dividend distribution and claiming.

   ```javascript
   const { expect } = require("chai");

   describe("DividendDistributionETF", function () {
     let dividendDistributionContract;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();
       const SecurityTokenMock = await ethers.getContractFactory("SecurityTokenMock");
       const securityToken = await SecurityTokenMock.deploy();
       await securityToken.deployed();

       const DividendDistributionETF = await ethers.getContractFactory("DividendDistributionETF");
       dividendDistributionContract = await DividendDistributionETF.deploy(securityToken.address);
       await dividendDistributionContract.deployed();

       // Issue tokens to the investor
       await securityToken.issueTokens(investor.address, 1000);
     });

     it("Should allow the owner to distribute dividends", async function () {
       await dividendDistributionContract.distributeDividends(1000);
       expect(await dividendDistributionContract.totalDividends()).to.equal(1000);
     });

     it("Should calculate dividends correctly", async function () {
       await dividendDistributionContract.distributeDividends(1000);
       const dividend = await dividendDistributionContract.calculateDividend(investor.address);
       expect(dividend).to.equal(1000); // Assuming investor owns 100% of the tokens for this test
     });

     it("Should allow investors to claim dividends", async function () {
       await dividendDistributionContract.distributeDividends(1000);
       await dividendDistributionContract.connect(investor).claimDividends();

       // Check the claimed dividends
       const claimed = await dividendDistributionContract.dividendsClaimed(investor.address);
       expect(claimed).to.equal(1000);
     });

     it("Should revert when claiming dividends if none are available", async function () {
       await expect(dividendDistributionContract.connect(investor).claimDividends()).to.be.revertedWith("No dividends to claim");
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
   - Provide step-by-step instructions on how to distribute dividends and claim returns.

3. **Developer Guide:**
   - Explain the contract architecture, including dividend calculation and distribution mechanisms.

This contract facilitates the automated distribution of dividends or yield from ETF investments, ensuring compliance and security for all transactions. If you need any further modifications or additions, feel free to ask!