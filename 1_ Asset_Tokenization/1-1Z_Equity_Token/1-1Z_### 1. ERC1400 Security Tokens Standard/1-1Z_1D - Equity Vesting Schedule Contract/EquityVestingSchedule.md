### Smart Contract: `EquityVestingSchedule.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/// @title Equity Vesting Schedule Contract
/// @notice This contract manages the vesting of equity tokens over time for employee stock options or founder shares.
contract EquityVestingSchedule is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VESTING_MANAGER_ROLE = keccak256("VESTING_MANAGER_ROLE");

    IERC1400 public equityToken;
    uint256 public totalVestedTokens;
    uint256 public totalReleasedTokens;

    struct VestingSchedule {
        uint256 startTime;
        uint256 cliffDuration;
        uint256 duration;
        uint256 totalAmount;
        uint256 releasedAmount;
        bool revoked;
    }

    mapping(address => VestingSchedule) private vestingSchedules;

    event VestingScheduled(
        address indexed beneficiary,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 duration,
        uint256 totalAmount
    );

    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary);

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC1400 token representing the equity
    constructor(address _equityToken) {
        require(_equityToken != address(0), "Invalid token address");

        equityToken = IERC1400(_equityToken);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VESTING_MANAGER_ROLE, msg.sender);
    }

    /// @notice Schedules a new vesting for a beneficiary
    /// @param beneficiary Address of the beneficiary
    /// @param startTime Start time of the vesting schedule
    /// @param cliffDuration Duration of the cliff period in seconds
    /// @param duration Total duration of the vesting schedule in seconds
    /// @param totalAmount Total amount of tokens to be vested
    function scheduleVesting(
        address beneficiary,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 duration,
        uint256 totalAmount
    ) external onlyRole(VESTING_MANAGER_ROLE) {
        require(beneficiary != address(0), "Invalid beneficiary address");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Vesting already exists for this beneficiary");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");

        vestingSchedules[beneficiary] = VestingSchedule({
            startTime: startTime,
            cliffDuration: cliffDuration,
            duration: duration,
            totalAmount: totalAmount,
            releasedAmount: 0,
            revoked: false
        });

        totalVestedTokens += totalAmount;
        emit VestingScheduled(beneficiary, startTime, cliffDuration, duration, totalAmount);
    }

    /// @notice Releases vested tokens for the beneficiary
    function releaseTokens() external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule found for this beneficiary");
        require(!schedule.revoked, "Vesting schedule is revoked");

        uint256 vestedAmount = calculateVestedAmount(msg.sender);
        uint256 releasableAmount = vestedAmount - schedule.releasedAmount;

        require(releasableAmount > 0, "No tokens to release");

        schedule.releasedAmount += releasableAmount;
        totalReleasedTokens += releasableAmount;

        equityToken.transfer(msg.sender, releasableAmount);
        emit TokensReleased(msg.sender, releasableAmount);
    }

    /// @notice Revokes the vesting schedule for a beneficiary
    /// @param beneficiary Address of the beneficiary
    function revokeVesting(address beneficiary) external onlyRole(VESTING_MANAGER_ROLE) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule found for this beneficiary");
        require(!schedule.revoked, "Vesting schedule already revoked");

        schedule.revoked = true;
        emit VestingRevoked(beneficiary);
    }

    /// @notice Calculates the total vested amount for a beneficiary
    /// @param beneficiary Address of the beneficiary
    /// @return vestedAmount The total vested amount
    function calculateVestedAmount(address beneficiary) public view returns (uint256 vestedAmount) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0) {
            return 0;
        }

        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }

        if (block.timestamp >= schedule.startTime + schedule.duration || schedule.revoked) {
            return schedule.totalAmount;
        }

        uint256 timeElapsed = block.timestamp - (schedule.startTime + schedule.cliffDuration);
        uint256 vestingDurationAfterCliff = schedule.duration - schedule.cliffDuration;
        vestedAmount = (schedule.totalAmount * timeElapsed) / vestingDurationAfterCliff;
    }

    /// @notice Gets the vesting schedule for a beneficiary
    /// @param beneficiary Address of the beneficiary
    /// @return schedule The vesting schedule
    function getVestingSchedule(address beneficiary) external view returns (VestingSchedule memory schedule) {
        return vestingSchedules[beneficiary];
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

    /// @notice Add new vesting manager
    /// @dev Only callable by an admin
    /// @param newVestingManager Address of the new vesting manager
    function addVestingManager(address newVestingManager) external onlyRole(ADMIN_ROLE) {
        grantRole(VESTING_MANAGER_ROLE, newVestingManager);
    }

    /// @notice Remove a vesting manager
    /// @dev Only callable by an admin
    /// @param vestingManager Address of the vesting manager to remove
    function removeVestingManager(address vestingManager) external onlyRole(ADMIN_ROLE) {
        revokeRole(VESTING_MANAGER_ROLE, vestingManager);
    }
}
```

### Key Features of the Contract:

1. **Access Control and Roles**:
   - Uses `AccessControl` from OpenZeppelin for role-based permissions.
   - Two primary roles:
     - `ADMIN_ROLE`: For overall management and administrative control.
     - `VESTING_MANAGER_ROLE`: For scheduling and managing vesting schedules.

2. **Vesting Schedule Management**:
   - Schedules a vesting period for beneficiaries with a start time, cliff duration, and total vesting duration.
   - Tokens are released according to the vesting schedule, and any vested amount can be released by the beneficiary.

3. **Releasable Amount Calculation**:
   - Calculates the vested amount based on the elapsed time from the start of the vesting and the cliff period.
   - Beneficiaries can only release tokens that are vested according to the vesting schedule.

4. **Vesting Revocation**:
   - Vesting schedules can be revoked by the `VESTING_MANAGER_ROLE`, preventing further token release.

5. **Administration and Management**:
   - `ADMIN_ROLE` can add or remove admins and vesting managers.

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

     const EquityVestingSchedule = await ethers.getContractFactory("EquityVestingSchedule");
     const equityVestingSchedule = await EquityVestingSchedule.deploy(equityToken.address);
     await equityVestingSchedule.deployed();

     console.log("Equity Vesting Schedule Contract deployed to:", equityVestingSchedule.address);
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

5. **Testing

 and Verification**:
   - Write unit tests to verify functionalities such as scheduling vesting, releasing tokens, and revoking vesting.
   - Perform a security audit to ensure compliance and security of the vesting mechanism.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

### Next Steps:

- **Advanced Vesting Features**: Add more complex vesting schedules, such as graded or performance-based vesting.
- **Integration with Equity Token Contracts**: Combine this vesting contract with other equity token management contracts to form a complete equity management solution.
- **Automated Alerts and Notifications**: Notify beneficiaries when their tokens become releasable or when a vesting schedule is revoked.

This contract provides a secure and effective way to manage the vesting of equity tokens over time, ensuring compliance with vesting agreements for employees, founders, or investors.