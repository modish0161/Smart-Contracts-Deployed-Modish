// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

contract AMLTransactionMonitoringVault is ERC4626, Ownable, AccessControl, Pausable {
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Thresholds for suspicious activity
    uint256 public largeDepositThreshold;
    uint256 public largeWithdrawalThreshold;

    // Events for suspicious activities
    event LargeDeposit(address indexed user, uint256 amount);
    event LargeWithdrawal(address indexed user, uint256 amount);
    event SuspiciousActivityReported(address indexed user, string activityType, uint256 amount, string reason);

    // Event for threshold updates
    event ThresholdUpdated(uint256 largeDepositThreshold, uint256 largeWithdrawalThreshold);

    // Constructor to initialize the contract
    constructor(
        IERC20 _asset,
        string memory name_,
        string memory symbol_,
        address complianceOfficer,
        uint256 _largeDepositThreshold,
        uint256 _largeWithdrawalThreshold
    ) ERC4626(_asset) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, complianceOfficer);

        largeDepositThreshold = _largeDepositThreshold;
        largeWithdrawalThreshold = _largeWithdrawalThreshold;

        _setMetadata(name_, symbol_);
    }

    /**
     * @dev Sets new thresholds for large deposits and withdrawals.
     * @param newLargeDepositThreshold The new threshold for large deposits.
     * @param newLargeWithdrawalThreshold The new threshold for large withdrawals.
     */
    function setThresholds(uint256 newLargeDepositThreshold, uint256 newLargeWithdrawalThreshold)
        external
        onlyRole(COMPLIANCE_OFFICER_ROLE)
    {
        largeDepositThreshold = newLargeDepositThreshold;
        largeWithdrawalThreshold = newLargeWithdrawalThreshold;
        emit ThresholdUpdated(newLargeDepositThreshold, newLargeWithdrawalThreshold);
    }

    /**
     * @dev Reports suspicious activity to the compliance officer.
     * @param user Address of the user involved in the suspicious activity.
     * @param activityType The type of suspicious activity (e.g., "deposit" or "withdrawal").
     * @param amount The amount involved in the suspicious activity.
     * @param reason The reason for flagging the activity as suspicious.
     */
    function reportSuspiciousActivity(
        address user,
        string calldata activityType,
        uint256 amount,
        string calldata reason
    ) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        emit SuspiciousActivityReported(user, activityType, amount, reason);
    }

    /**
     * @dev Override deposit function to include AML monitoring.
     * @param assets Amount of assets to deposit.
     * @param receiver Address of the receiver of the shares.
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        if (assets >= largeDepositThreshold) {
            emit LargeDeposit(receiver, assets);
            reportSuspiciousActivity(receiver, "deposit", assets, "Large deposit exceeding threshold");
        }
        return super.deposit(assets, receiver);
    }

    /**
     * @dev Override withdraw function to include AML monitoring.
     * @param assets Amount of assets to withdraw.
     * @param receiver Address of the receiver of the assets.
     * @param owner Address of the owner of the shares.
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        if (assets >= largeWithdrawalThreshold) {
            emit LargeWithdrawal(owner, assets);
            reportSuspiciousActivity(owner, "withdrawal", assets, "Large withdrawal exceeding threshold");
        }
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @dev Pauses all vault operations in case of a security issue.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all vault operations.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Fallback function to reject Ether transfers.
     */
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
