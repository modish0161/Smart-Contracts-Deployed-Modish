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
