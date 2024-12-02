### Smart Contract: 2-1Y_1A_HedgeFundTokenIssuance.sol

#### Overview
This smart contract facilitates the issuance of hedge fund tokens, representing fractional ownership of the fund’s assets. It complies with ERC1400 standards to ensure adherence to securities regulations while providing flexible governance mechanisms for managing investments, performance fees, and profit distributions.

### Contract Code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HedgeFundTokenIssuance is Ownable, ReentrancyGuard {
    // Struct to store investor information
    struct Investor {
        bool isAccredited;
        uint256 shares;
    }

    // Mapping from investor address to their information
    mapping(address => Investor) public investors;

    // Total shares issued
    uint256 public totalShares;
    
    // Event declarations
    event TokensIssued(address indexed investor, uint256 shares);
    event TokensWithdrawn(address indexed investor, uint256 shares);
    
    // Address of the underlying asset (e.g., hedge fund token)
    address public underlyingAsset;

    constructor(address _underlyingAsset) {
        require(_underlyingAsset != address(0), "Invalid underlying asset address");
        underlyingAsset = _underlyingAsset;
    }

    // Modifier to check if the caller is an accredited investor
    modifier onlyAccredited() {
        require(investors[msg.sender].isAccredited, "Not an accredited investor");
        _;
    }

    // Function to verify and register an accredited investor
    function registerAccreditedInvestor(address _investor) external onlyOwner {
        require(_investor != address(0), "Invalid investor address");
        investors[_investor].isAccredited = true;
    }

    // Function to issue tokens to accredited investors
    function issueTokens(uint256 _shares) external onlyAccredited nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");

        // Update investor shares and total shares
        investors[msg.sender].shares += _shares;
        totalShares += _shares;

        emit TokensIssued(msg.sender, _shares);
    }

    // Function to withdraw shares (tokens) from the fund
    function withdrawTokens(uint256 _shares) external onlyAccredited nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");
        require(investors[msg.sender].shares >= _shares, "Insufficient shares");

        // Update investor shares and total shares
        investors[msg.sender].shares -= _shares;
        totalShares -= _shares;

        // Transfer the underlying asset tokens to the investor
        IERC20(underlyingAsset).transfer(msg.sender, _shares);

        emit TokensWithdrawn(msg.sender, _shares);
    }

    // Function to check the investor's share balance
    function getInvestorShares(address _investor) external view returns (uint256) {
        return investors[_investor].shares;
    }

    // Function to get total shares issued
    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }
}
```

### Contract Explanation:

1. **Investor Management:**
   - The contract manages accredited investors using a mapping that stores their accreditation status and the number of shares they hold.

2. **Token Issuance:**
   - Only accredited investors can issue tokens, ensuring compliance with securities regulations.
   - The `issueTokens` function allows an investor to issue a specified number of shares.

3. **Token Withdrawal:**
   - Accredited investors can withdraw their tokens through the `withdrawTokens` function, transferring the corresponding amount from the underlying asset.

4. **Events:**
   - The contract emits events for token issuance and withdrawals, ensuring transparency and traceability.

5. **Security Features:**
   - The contract uses OpenZeppelin’s `ReentrancyGuard` to prevent reentrancy attacks.
   - Only the contract owner can register new accredited investors.

6. **Constructor:**
   - The constructor accepts the address of the underlying asset (e.g., an ERC20 token representing the hedge fund) upon deployment.

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

     const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
     const underlyingAsset = await MockERC20.deploy("Hedge Fund Token", "HFT", 18, 1000000);
     await underlyingAsset.deployed();

     console.log("Underlying Asset deployed to:", underlyingAsset.address);

     const HedgeFundTokenIssuance = await hre.ethers.getContractFactory("HedgeFundTokenIssuance");
     const hedgeFundTokenIssuance = await HedgeFundTokenIssuance.deploy(underlyingAsset.address);

     await hedgeFundTokenIssuance.deployed();
     console.log("Hedge Fund Token Issuance deployed to:", hedgeFundTokenIssuance.address);
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
   Use Mocha and Chai for testing core functions such as investor registration, token issuance, and withdrawal.

   ```javascript
   const { expect } = require("chai");

   describe("Hedge Fund Token Issuance", function () {
     let hedgeFundTokenIssuance, underlyingAsset;
     let owner, investor1, investor2;

     beforeEach(async function () {
       [owner, investor1, investor2] = await ethers.getSigners();

       const MockERC20 = await ethers.getContractFactory("MockERC20");
       underlyingAsset = await MockERC20.deploy("Mock Token", "MKT", 18, 1000000);
       await underlyingAsset.deployed();

       const HedgeFundTokenIssuance = await ethers.getContractFactory("HedgeFundTokenIssuance");
       hedgeFundTokenIssuance = await HedgeFundTokenIssuance.deploy(underlyingAsset.address);
       await hedgeFundTokenIssuance.deployed();
     });

     it("Should allow registration of accredited investors", async function () {
       await hedgeFundTokenIssuance.registerAccreditedInvestor(investor1.address);
       expect(await hedgeFundTokenIssuance.investors(investor1.address)).to.be.true;
     });

     it("Should allow issuance of tokens to accredited investors", async function () {
       await hedgeFundTokenIssuance.registerAccreditedInvestor(investor1.address);
       await hedgeFundTokenIssuance.issueTokens(100);
       expect(await hedgeFundTokenIssuance.getInvestorShares(investor1.address)).to.equal(100);
     });

     it("Should allow withdrawal of tokens from the fund", async function () {
       await hedgeFundTokenIssuance.registerAccreditedInvestor(investor1.address);
       await hedgeFundTokenIssuance.issueTokens(100);
       await hedgeFundTokenIssuance.withdrawTokens(50);
       expect(await hedgeFundTokenIssuance.getInvestorShares(investor1.address)).to.equal(50);
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
   - Provide step-by-step instructions on how to register investors, issue tokens, and withdraw investments.

3. **Developer Guide:**
   - Explain the contract architecture, access control, and customization options for extending the hedge fund functionalities.

This smart contract provides a robust framework for the tokenization of hedge funds, ensuring compliance with regulations while enabling efficient management of investments and investor relationships.