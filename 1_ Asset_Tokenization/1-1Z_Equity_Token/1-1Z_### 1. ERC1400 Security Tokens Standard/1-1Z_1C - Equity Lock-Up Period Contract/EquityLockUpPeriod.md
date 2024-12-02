### Smart Contract: `EquityLockUpPeriod.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/// @title Equity Lock-Up Period Contract
/// @notice This contract implements a lock-up period on equity tokens (ERC1400) to prevent transfer or sale during the specified lock-up duration.
contract EquityLockUpPeriod is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LOCK_MANAGER_ROLE = keccak256("LOCK_MANAGER_ROLE");

    IERC1400 public equityToken;
    mapping(address => uint256) private lockUpEndTimes;

    event LockUpSet(address indexed investor, uint256 lockUpEndTime);
    event LockUpReleased(address indexed investor);

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC1400 token representing the equity
    constructor(address _equityToken) {
        require(_equityToken != address(0), "Invalid token address");

        equityToken = IERC1400(_equityToken);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(LOCK_MANAGER_ROLE, msg.sender);
    }

    /// @notice Sets the lock-up period for a specific investor
    /// @param investor Address of the investor
    /// @param lockUpDuration Duration of the lock-up period in seconds
    function setLockUpPeriod(address investor, uint256 lockUpDuration)
        external
        onlyRole(LOCK_MANAGER_ROLE)
    {
        require(investor != address(0), "Invalid investor address");
        require(lockUpDuration > 0, "Lock-up duration must be greater than zero");

        uint256 lockUpEndTime = block.timestamp + lockUpDuration;
        lockUpEndTimes[investor] = lockUpEndTime;

        emit LockUpSet(investor, lockUpEndTime);
    }

    /// @notice Removes the lock-up period for a specific investor
    /// @param investor Address of the investor
    function removeLockUpPeriod(address investor) external onlyRole(LOCK_MANAGER_ROLE) {
        require(investor != address(0), "Invalid investor address");

        lockUpEndTimes[investor] = 0;
        emit LockUpReleased(investor);
    }

    /// @notice Checks if an investor is currently under lock-up period
    /// @param investor Address of the investor to check
    /// @return bool True if the investor is under lock-up, false otherwise
    function isLockedUp(address investor) external view returns (bool) {
        return block.timestamp < lockUpEndTimes[investor];
    }

    /// @notice Transfers tokens with lock-up compliance
    /// @param from Address of the sender
    /// @param to Address of the recipient
    /// @param value Amount of tokens to transfer
    function transferWithLockUpCompliance(
        address from,
        address to,
        uint256 value
    ) external whenNotPaused nonReentrant {
        require(block.timestamp >= lockUpEndTimes[from], "Sender is under lock-up period");
        require(block.timestamp >= lockUpEndTimes[to], "Recipient is under lock-up period");

        equityToken.transferFrom(from, to, value);
    }

    /// @notice Pause the contract
    /// @dev Only callable by the contract admin
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only callable by the contract admin
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Add new admin
    /// @dev Only callable by an existing admin
    /// @param newAdmin Address of the new admin
    function addAdmin(address newAdmin) external onlyRole(ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, newAdmin);
    }

    /// @notice Remove an admin
    /// @dev Only callable by an existing admin
    /// @param admin Address of the admin to remove
    function removeAdmin(address admin) external onlyRole(ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, admin);
    }

    /// @notice Add new lock manager
    /// @dev Only callable by an admin
    /// @param newLockManager Address of the new lock manager
    function addLockManager(address newLockManager) external onlyRole(ADMIN_ROLE) {
        grantRole(LOCK_MANAGER_ROLE, newLockManager);
    }

    /// @notice Remove a lock manager
    /// @dev Only callable by an admin
    /// @param lockManager Address of the lock manager to remove
    function removeLockManager(address lockManager) external onlyRole(ADMIN_ROLE) {
        revokeRole(LOCK_MANAGER_ROLE, lockManager);
    }
}
```

### Key Features of the Contract:

1. **Access Control and Roles**:
   - Utilizes `AccessControl` from OpenZeppelin for role-based permissions.
   - Two primary roles:
     - `ADMIN_ROLE`: For overall management and administrative control.
     - `LOCK_MANAGER_ROLE`: For managing the lock-up periods of investors.

2. **Lock-Up Management**:
   - Allows `LOCK_MANAGER_ROLE` to set and remove lock-up periods for specific investors.
   - Investors under lock-up cannot transfer their tokens until the lock-up period expires.

3. **Lock-Up Compliance Check**:
   - The `transferWithLockUpCompliance` function checks if the sender and recipient are under a lock-up period before transferring tokens.
   - This ensures tokens can only be transferred when the lock-up period has ended.

4. **Pausable Contract**:
   - The contract can be paused by an admin in case of an emergency, stopping all token transfers.

5. **Flexible Role Management**:
   - Admins can dynamically add or remove other admins and lock managers.

### Deployment Instructions:

1. **Install Dependencies**:
   Install the required OpenZeppelin contracts:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Use Hardhat or Truffle to compile the contract:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script using Hardhat or Truffle:

   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     const EquityToken = await ethers.getContractFactory("EquityToken");
     const equityToken = await EquityToken.deploy();
     await equityToken.deployed();

     console.log("Equity Token deployed to:", equityToken.address);

     const EquityLockUpPeriod = await ethers.getContractFactory("EquityLockUpPeriod");
     const equityLockUpPeriod = await EquityLockUpPeriod.deploy(equityToken.address);
     await equityLockUpPeriod.deployed();

     console.log("Equity Lock-Up Period Contract deployed to:", equityLockUpPeriod.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

4. **Run the Deployment Script**:
   Deploy the contract using Hardhat:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

5. **Testing and Verification**:
   - Write unit tests to verify functionalities such as setting/removing lock-ups and transferring tokens under compliance.
   - Perform a security audit to ensure compliance and security of the lock-up mechanism.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

### Next Steps:

- **Vesting and Release Schedules**: Implement more complex vesting schedules for gradual release of tokens over time.
- **Integration with Other Compliance Contracts**: Integrate with whitelist/blacklist compliance contracts to ensure regulatory adherence.
- **Automated Alerts and Notifications**: Notify investors when their lock-up period is about to end.

This contract provides a secure and effective way to enforce lock-up periods for equity tokens, ensuring compliance with lock-up agreements for early investors, founders, or employees.