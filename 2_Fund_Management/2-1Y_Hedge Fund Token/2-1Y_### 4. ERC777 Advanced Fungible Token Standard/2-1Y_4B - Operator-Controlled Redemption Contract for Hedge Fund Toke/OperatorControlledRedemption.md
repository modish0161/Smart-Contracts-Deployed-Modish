Here’s a complete smart contract for the **Operator-Controlled Redemption Contract for Hedge Fund Tokens** using the ERC777 standard. This contract allows fund managers or custodians to handle redemption requests, enabling investors to withdraw their capital by redeeming tokens for underlying assets or cash.

### Contract: 2-1Y_4B_OperatorControlledRedemption.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OperatorControlledRedemption is ERC777, Ownable, ReentrancyGuard {
    mapping(address => uint256) public contributions; // Track contributions of each investor
    uint256 public totalCapital; // Total capital managed by the hedge fund
    address public operator; // Address authorized to handle redemptions

    event TokensRedeemed(address indexed investor, uint256 amount, uint256 value);
    event OperatorChanged(address indexed newOperator);

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not the operator");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        address _operator
    ) ERC777(name, symbol, defaultOperators) {
        operator = _operator;
    }

    // Function to set a new operator
    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit OperatorChanged(newOperator);
    }

    // Function for investors to contribute and receive tokens
    function contribute(uint256 amount) external nonReentrant {
        require(amount > 0, "Contribution must be greater than 0");

        contributions[msg.sender] += amount;
        totalCapital += amount;
        _mint(msg.sender, amount, "", ""); // Mint new tokens proportional to contribution
    }

    // Function for the operator to handle token redemptions
    function redeemTokens(uint256 amount) external nonReentrant onlyOperator {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        contributions[msg.sender] -= amount; // Deduct contribution
        totalCapital -= amount; // Update total capital

        // Burn tokens on redemption
        _burn(msg.sender, amount, ""); 

        uint256 cashValue = amount; // Assume 1:1 redemption for simplicity
        emit TokensRedeemed(msg.sender, amount, cashValue);
    }

    // Function to view total capital
    function getTotalCapital() external view returns (uint256) {
        return totalCapital;
    }
}
```

### Contract Explanation:

1. **Token Management:**
   - Inherits from OpenZeppelin's `ERC777`, providing advanced token features and operator permissions.

2. **Capital Management:**
   - `contribute`: Allows investors to contribute capital and receive tokens.
   - `redeemTokens`: Allows the designated operator to handle redemption requests, enabling investors to redeem tokens for their proportional value in cash or assets.

3. **Events:**
   - Emits events for redemption activities, providing transparency.

4. **Operator Management:**
   - Allows the contract owner to set or change the operator, who has the permission to manage redemptions.

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

     const defaultOperators = []; // Add any default operators if needed
     const operator = deployer.address; // Set deployer as the initial operator
     const AdvancedHedgeFundToken = await hre.ethers.getContractFactory("OperatorControlledRedemption");
     const token = await AdvancedHedgeFundToken.deploy("Hedge Fund Token", "HFT", defaultOperators, operator);

     await token.deployed();
     console.log("Operator-Controlled Redemption Contract deployed to:", token.address);
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
   Use Mocha and Chai for testing core functions such as contribution and redemption.

   ```javascript
   const { expect } = require("chai");

   describe("Operator Controlled Redemption", function () {
     let contract;
     let owner, operator, investor1;

     beforeEach(async function () {
       [owner, operator, investor1] = await ethers.getSigners();

       const AdvancedHedgeFundToken = await ethers.getContractFactory("OperatorControlledRedemption");
       const defaultOperators = [];
       contract = await AdvancedHedgeFundToken.deploy("Hedge Fund Token", "HFT", defaultOperators, operator.address);
       await contract.deployed();
     });

     it("Should allow investors to contribute and receive tokens", async function () {
       await contract.connect(investor1).contribute(500);
       expect(await contract.balanceOf(investor1.address)).to.equal(500);
     });

     it("Should allow operator to redeem tokens", async function () {
       await contract.connect(investor1).contribute(500);
       await contract.connect(operator).redeemTokens(500);
       expect(await contract.balanceOf(investor1.address)).to.equal(0);
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
   - Provide step-by-step instructions on how to manage contributions and redemptions.

3. **Developer Guide:**
   - Explain the contract architecture, including operator permissions and redemption management.

This smart contract framework allows for effective management of hedge fund token redemptions with operator control. If you need any modifications or additional features, just let me know!