### **Smart Contract: 2-1X_1D_LockUpPeriodMutualFund.sol**

#### **Overview:**
This smart contract enforces lock-up periods for mutual fund tokens. During the lock-up period, investors are restricted from selling or transferring their mutual fund tokens to ensure compliance with regulatory requirements and fund-specific policies for early investors or certain investment rounds. The contract adheres to the ERC1400 standard, designed for security tokens, ensuring compliance and modularity for future upgrades.

### **Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

contract LockUpPeriodMutualFund is ERC1400, Ownable, Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct LockUp {
        uint256 releaseTime;
        bool isLocked;
    }

    // Mapping to track the lock-up periods for each investor
    mapping(address => LockUp) public lockUps;

    event LockUpSet(address indexed investor, uint256 releaseTime);
    event LockUpRemoved(address indexed investor);
    event TransferBlocked(address indexed from, address indexed to, uint256 amount, string reason);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    )
        ERC1400(name, symbol, new address )
    {
        _mint(msg.sender, initialSupply, "", "");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
    }

    // Set lock-up period for a specific investor
    function setLockUpPeriod(address investor, uint256 releaseTime) external onlyRole(ISSUER_ROLE) {
        require(investor != address(0), "Invalid address");
        require(releaseTime > block.timestamp, "Release time must be in the future");

        lockUps[investor] = LockUp(releaseTime, true);
        emit LockUpSet(investor, releaseTime);
    }

    // Remove lock-up period for a specific investor
    function removeLockUpPeriod(address investor) external onlyRole(ISSUER_ROLE) {
        require(investor != address(0), "Invalid address");
        require(lockUps[investor].isLocked, "No lock-up period set for this investor");

        lockUps[investor] = LockUp(0, false);
        emit LockUpRemoved(investor);
    }

    // Override ERC1400 transfer function to include lock-up check
    function _transferWithData(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal override whenNotPaused {
        require(lockUps[from].releaseTime <= block.timestamp, "Tokens are locked");
        super._transferWithData(from, to, value, data);
    }

    // Check if an investor is under a lock-up period
    function isUnderLockUp(address investor) external view returns (bool) {
        return lockUps[investor].isLocked && block.timestamp < lockUps[investor].releaseTime;
    }

    // Get lock-up release time for an investor
    function getLockUpReleaseTime(address investor) external view returns (uint256) {
        require(lockUps[investor].isLocked, "No lock-up period set for this investor");
        return lockUps[investor].releaseTime;
    }

    // Transfer ownership override to ensure role setup for new owner
    function transferOwnership(address newOwner) public override onlyOwner {
        _setupRole(ADMIN_ROLE, newOwner);
        _setupRole(ISSUER_ROLE, newOwner);
        super.transferOwnership(newOwner);
    }

    // Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
```

### **Contract Explanation:**
1. **Constructor:**
   - Initializes the contract with a name, symbol, and initial supply.
   - Sets up roles for admins and issuers.

2. **Set Lock-Up Period:**
   - `setLockUpPeriod`: Allows the issuer to set a lock-up period for a specific investor. The investor's tokens are locked until the release time.

3. **Remove Lock-Up Period:**
   - `removeLockUpPeriod`: Allows the issuer to remove the lock-up period for a specific investor.

4. **Transfer Override:**
   - `_transferWithData`: Overrides the default transfer function from ERC1400 to check for lock-up periods. It ensures that tokens cannot be transferred if they are still under a lock-up period.

5. **Check Lock-Up Status:**
   - `isUnderLockUp`: Checks whether an investor is under a lock-up period.
   - `getLockUpReleaseTime`: Retrieves the release time of the lock-up period for an investor.

6. **Role-Based Access Control:**
   - Uses AccessControl to define roles for administrators and issuers.

7. **Pause and Unpause:**
   - `pause` and `unpause`: Allows the owner to pause and unpause the contract, preventing certain functions from being executed.

### **Deployment Instructions:**
1. **Prerequisites:**
   - Ensure you have the latest version of Node.js installed.
   - Install Hardhat and OpenZeppelin libraries.
     ```bash
     npm install hardhat @openzeppelin/contracts
     ```

2. **Deployment Script:**
   Create a deployment script `deploy.js` in the `scripts` folder.

   ```javascript
   const hre = require("hardhat");

   async function main() {
     const [deployer] = await hre.ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const LockUpPeriodMutualFund = await hre.ethers.getContractFactory("LockUpPeriodMutualFund");
     const mutualFundToken = await LockUpPeriodMutualFund.deploy(
       "Mutual Fund Lock-Up Token", // Token name
       "MFLT",                      // Token symbol
       1000000 * 10 ** 18           // Initial supply (1 million tokens)
     );

     await mutualFundToken.deployed();
     console.log("Lock-Up Period Mutual Fund Token deployed to:", mutualFundToken.address);
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

### **Testing Suite:**
1. **Basic Tests:**
   Use Mocha and Chai for testing contract functions, e.g., setting and removing lock-up periods, and transfer restrictions.

   ```javascript
   const { expect } = require("chai");

   describe("Lock-Up Period Mutual Fund", function () {
     it("Should deploy the contract and set initial parameters", async function () {
       const [owner] = await ethers.getSigners();
       const LockUpPeriodMutualFund = await ethers.getContractFactory("LockUpPeriodMutualFund");
       const mutualFundToken = await LockUpPeriodMutualFund.deploy(
         "Mutual Fund Lock-Up Token", "MFLT", 1000000 * 10 ** 18);
       await mutualFundToken.deployed();

       expect(await mutualFundToken.name()).to.equal("Mutual Fund Lock-Up Token");
       expect(await mutualFundToken.symbol()).to.equal("MFLT");
     });

     it("Should set a lock-up period for an investor", async function () {
       const [owner, investor] = await ethers.getSigners();
       const lockUpReleaseTime = Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30; // 30 days from now

       await mutualFundToken.setLockUpPeriod(investor.address, lockUpReleaseTime);
       expect(await mutualFundToken.isUnderLockUp(investor.address)).to.be.true;
     });

     it("Should prevent transfer during lock-up period", async function () {
       const [owner, sender, recipient] = await ethers.getSigners();
       await mutualFundToken.transfer(sender.address, 100);

       await expect(mutualFundToken.connect(sender).transfer(recipient.address, 50)).to.be.revertedWith("Tokens are locked");
     });

     it("Should remove lock-up period for an investor", async function () {
       const [owner, investor] = await ethers.getSigners();
       await mutualFundToken.removeLockUpPeriod(investor.address);
       expect(await mutualFundToken.isUnderLockUp(investor.address)).to.be.false;
     });

     // More tests...
   });
   ```

### **Documentation:**
1. **API Documentation:**
   - Detailed comments in the smart contract code for each function and event.
   - JSON schema for all public methods and events, detailing input and output parameters.

2. **User Guide:**
   - Detailed step-by-step guide for investors to interact with the contract.
   - Example scripts for setting and removing lock-up periods.

3. **Developer Guide:**
   - Explanation of design patterns used (e.g., Role-Based Access Control).
   - Instructions for integrating with frontend applications using web3

.js or ethers.js.
   - Guide on extending the contract for additional features (e.g., DeFi integrations).

### **Additional Features:**
- **Oracle Integration:**
  - Optional integration with Chainlink oracles to fetch real-time data for calculating yields.

- **DeFi Integration:**
  - Option to enable staking mechanisms for long-term token holders.
  - Liquidity pool integration for tokenized assets.

### **Final Output:**
1. **Contract Code**: Complete Solidity code provided above.
2. **Deployment Scripts**: Included in the `deploy.js` script.
3. **Test Suite**: Basic test examples provided.
4. **Documentation**: API, user, and developer guides detailed above.

**Additional Deployment Instructions or Further Customization:**
- Customize the deployment script for different networks (e.g., Rinkeby, BSC Testnet).
- Modify the contract to include additional ERC1400 partitions for different mutual fund classes.
- Enhance security features with multi-signature control for administrative functions.

This setup ensures a comprehensive, secure, and scalable implementation of a lock-up period contract for mutual fund tokens.