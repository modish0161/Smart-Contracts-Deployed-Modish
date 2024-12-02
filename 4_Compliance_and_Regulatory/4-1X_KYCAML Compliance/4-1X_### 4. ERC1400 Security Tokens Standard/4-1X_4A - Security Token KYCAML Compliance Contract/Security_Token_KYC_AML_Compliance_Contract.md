### Smart Contract: 4-1X_4A_Security_Token_KYC_AML_Compliance_Contract.sol

This smart contract utilizes the **ERC1400** standard to ensure that only verified investors can hold and transfer security tokens. It enforces KYC/AML checks before users can participate in token sales or secondary trading, ensuring compliance with securities regulations.

#### **Solidity Code: 4-1X_4A_Security_Token_KYC_AML_Compliance_Contract.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";  // Import the ERC1400 standard (Assuming the interface exists in your project)

// Custom implementation of ERC1400
contract SecurityTokenKYCAMLComplianceContract is ERC1400, Ownable, AccessControl, Pausable, ReentrancyGuard {
    
    // Role for KYC/AML compliance officers
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Mapping to store KYC approval status for users
    mapping(address => bool) private _kycApproved;

    // Mapping to store restricted addresses
    mapping(address => bool) private _restricted;

    // Event to log KYC approval
    event KYCApproved(address indexed user);

    // Event to log KYC revocation
    event KYCRevoked(address indexed user);

    // Event to log restriction of addresses
    event Restricted(address indexed user, string reason);

    // Event to log unrestriction of addresses
    event Unrestricted(address indexed user, string reason);

    // Modifier to check if the user is KYC approved
    modifier onlyKYCApproved(address user) {
        require(_kycApproved[user], "User is not KYC approved");
        _;
    }

    // Modifier to check if the user is not restricted
    modifier notRestricted(address user) {
        require(!_restricted[user], "User is restricted");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory controllers,
        address complianceOfficer
    ) ERC1400(name, symbol, controllers) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, complianceOfficer);
    }

    /**
     * @dev Approves KYC for a user.
     * @param user Address to approve KYC.
     */
    function approveKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = true;
        emit KYCApproved(user);
    }

    /**
     * @dev Revokes KYC for a user.
     * @param user Address to revoke KYC.
     */
    function revokeKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = false;
        emit KYCRevoked(user);
    }

    /**
     * @dev Restricts a user from holding or transferring assets.
     * @param user Address to restrict.
     * @param reason Reason for restriction.
     */
    function restrict(address user, string calldata reason) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[user] = true;
        emit Restricted(user, reason);
    }

    /**
     * @dev Unrestricts a user from holding or transferring assets.
     * @param user Address to unrestrict.
     * @param reason Reason for unrestriction.
     */
    function unrestrict(address user, string calldata reason) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[user] = false;
        emit Unrestricted(user, reason);
    }

    /**
     * @dev Checks if a user is KYC approved.
     * @param user Address to check.
     * @return true if the user is KYC approved, false otherwise.
     */
    function isKYCApproved(address user) external view returns (bool) {
        return _kycApproved[user];
    }

    /**
     * @dev Checks if a user is restricted.
     * @param user Address to check.
     * @return true if the user is restricted, false otherwise.
     */
    function isRestricted(address user) external view returns (bool) {
        return _restricted[user];
    }

    /**
     * @dev Overridden transfer function to include KYC and restriction checks.
     */
    function transfer(
        address to,
        uint256 value
    ) public override onlyKYCApproved(msg.sender) notRestricted(msg.sender) notRestricted(to) whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Overridden transferFrom function to include KYC and restriction checks.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override onlyKYCApproved(from) notRestricted(from) notRestricted(to) whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overridden transferByPartition function to include KYC and restriction checks.
     */
    function transferByPartition(
        bytes32 partition,
        address to,
        uint256 value,
        bytes calldata data
    ) public override onlyKYCApproved(msg.sender) notRestricted(msg.sender) notRestricted(to) whenNotPaused returns (bytes32) {
        return super.transferByPartition(partition, to, value, data);
    }

    /**
     * @dev Mint new tokens with KYC and restriction checks.
     */
    function mint(
        address account,
        uint256 amount,
        bytes memory data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyKYCApproved(account) notRestricted(account) {
        _mint(account, amount, data);
    }

    /**
     * @dev Burn tokens with KYC and restriction checks.
     */
    function burn(
        address account,
        uint256 amount,
        bytes memory data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyKYCApproved(account) notRestricted(account) {
        _burn(account, amount, data);
    }

    /**
     * @dev Function to pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Function to unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfers.
     */
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
```

### **Key Features and Functionalities:**

1. **Security Token KYC/AML Compliance:**
   - Users must be KYC-approved before they can hold, transfer, or receive security tokens, ensuring compliance with securities regulations.

2. **Flexible Compliance Management:**
   - Compliance officers can approve or revoke KYC status, and restrict or unrestrict users based on compliance requirements.

3. **Advanced ERC1400 Standard:**
   - The contract uses the **ERC1400** standard, which includes features such as partitioning, document management, and transfer restrictions specific to security tokens.

4. **Pausable Contract:**
   - The contract can be paused by the owner in the event of a security breach, halting all token transfers during the pause.

### **Deployment Instructions:**

1. **Prerequisites:**
   - Ensure Node.js, Hardhat, and OpenZeppelin Contracts are installed:
     ```
     npm install @openzeppelin/contracts
     ```

2. **Deploy Script (deploy.js):**
```javascript
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const name = "SecurityToken";
    const symbol = "STK";
    const controllers = []; // List of controller addresses for ERC1400 partition management
    const complianceOfficer = deployer.address; // Use deployer as compliance officer for demo purposes

    const SecurityTokenKYCAMLComplianceContract = await hre.ethers.getContractFactory("SecurityTokenKYCAMLComplianceContract");
    const contract = await SecurityTokenKYCAMLComplianceContract.deploy(name, symbol, controllers, complianceOfficer);

    await contract.deployed();
    console.log("SecurityTokenKYCAMLComplianceContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});
```

3. **Deployment Steps:**
   - Save the contract as `4-1X_4A_Security_Token_KYC_AML_Compliance_Contract.sol` in the `contracts` directory.
   - Save the deploy script as `deploy.js` in the `scripts` directory.
   - Deploy the contract using:
     ```
     npx hardhat run scripts/deploy.js --network [network_name]
     ```

### **Testing Instructions:**

1. **Test Cases (test/SecurityTokenKYCAMLComplianceContract.test.js):**
```javascript
const { expect } = require("chai");

describe("SecurityTokenKYCAMLComplianceContract", function () {
    let SecurityTokenKYCAMLComplianceContract, contract, owner, complianceOfficer, addr1, addr2;

    beforeEach(async function () {
        [owner, complianceOfficer, addr1, addr2] = await ethers.getSigners();
        const SecurityTokenKYCAMLComplianceContract = await ethers.getContractFactory("SecurityTokenKYCAMLComplianceContract");
        contract = await SecurityTokenKYCAMLComplianceContract.deploy

("SecurityToken", "STK", [], complianceOfficer.address);
        await contract.deployed();
    });

    it("Should approve KYC for a user", async function () {
        await contract.connect(complianceOfficer).approveKYC(addr1.address);
        expect(await contract.isKYCApproved(addr1.address)).to.equal(true);
    });

    it("Should restrict and unrestrict a user", async function () {
        await contract.connect(complianceOfficer).restrict(addr1.address, "AML violation");
        await expect(contract.connect(addr1).transfer(addr2.address, 10)).to.be.revertedWith("User is restricted");
        await contract.connect(complianceOfficer).unrestrict(addr1.address, "Cleared AML check");
        await expect(contract.connect(addr1).transfer(addr2.address, 10)).to.not.be.reverted;
    });

    it("Should allow only KYC-approved users to transfer tokens", async function () {
        await contract.connect(complianceOfficer).approveKYC(addr1.address);
        await contract.connect(owner).mint(addr1.address, 100, []);
        await expect(contract.connect(addr1).transfer(addr2.address, 10)).to.not.be.reverted;
    });

    it("Should prevent non-KYC users from transferring tokens", async function () {
        await contract.connect(owner).mint(addr1.address, 100, []);
        await expect(contract.connect(addr1).transfer(addr2.address, 10)).to.be.revertedWith("User is not KYC approved");
    });
});
```

2. Run the tests:
   ```
   npx hardhat test
   ```

### **Documentation and Additional Features:**

1. **API Documentation:**
   - Use Natspec comments for function definitions to generate detailed API documentation.

2. **User Guide:**
   - Include instructions for compliance officers on how to approve KYC, restrict/unrestrict users, and manage security tokens.

3. **Future Enhancements:**
   - Integrate third-party KYC/AML providers for automated compliance updates.
   - Implement more granular compliance controls, such as token-specific restrictions or thresholds.

This smart contract provides a robust ERC1400 implementation for security token KYC/AML compliance, allowing operators to manage security tokens and ensure compliance with regulatory requirements efficiently.