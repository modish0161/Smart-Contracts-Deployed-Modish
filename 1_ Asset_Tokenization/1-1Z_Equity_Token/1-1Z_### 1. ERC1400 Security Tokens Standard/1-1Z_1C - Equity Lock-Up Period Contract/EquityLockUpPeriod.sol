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
