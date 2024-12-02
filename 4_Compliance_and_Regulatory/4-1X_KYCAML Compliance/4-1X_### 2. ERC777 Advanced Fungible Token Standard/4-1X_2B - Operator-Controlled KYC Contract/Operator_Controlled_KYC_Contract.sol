// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OperatorControlledKYCContract is ERC777, Ownable, AccessControl, Pausable, ReentrancyGuard {

    // Role for KYC operators
    bytes32 public constant KYC_OPERATOR_ROLE = keccak256("KYC_OPERATOR_ROLE");

    // Mapping to track KYC approval status
    mapping(address => bool) private _kycApproved;

    // Mapping to track restricted addresses
    mapping(address => bool) private _restricted;

    // Event to log restriction of addresses
    event Restricted(address indexed user, string reason);

    // Event to log unrestriction of addresses
    event Unrestricted(address indexed user, string reason);

    // Event to log KYC approval
    event KYCApproved(address indexed user);

    // Event to log KYC revocation
    event KYCRevoked(address indexed user);

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
        address[] memory defaultOperators,
        address kycOperator
    ) ERC777("OperatorKYCAMLToken", "OKAT", defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(KYC_OPERATOR_ROLE, kycOperator);
    }

    /**
     * @dev Approves KYC for a user.
     * @param user Address to approve KYC.
     */
    function approveKYC(address user) external onlyRole(KYC_OPERATOR_ROLE) {
        _kycApproved[user] = true;
        emit KYCApproved(user);
    }

    /**
     * @dev Revokes KYC for a user.
     * @param user Address to revoke KYC.
     */
    function revokeKYC(address user) external onlyRole(KYC_OPERATOR_ROLE) {
        _kycApproved[user] = false;
        emit KYCRevoked(user);
    }

    /**
     * @dev Restricts a user from transferring tokens.
     * @param user Address to restrict.
     * @param reason Reason for restriction.
     */
    function restrict(address user, string calldata reason) external onlyRole(KYC_OPERATOR_ROLE) {
        _restricted[user] = true;
        emit Restricted(user, reason);
    }

    /**
     * @dev Unrestricts a user from transferring tokens.
     * @param user Address to unrestrict.
     * @param reason Reason for unrestriction.
     */
    function unrestrict(address user, string calldata reason) external onlyRole(KYC_OPERATOR_ROLE) {
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
     * @dev Overridden send function to include KYC and restriction checks.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) public override onlyKYCApproved(_msgSender()) notRestricted(_msgSender()) notRestricted(recipient) {
        super.send(recipient, amount, data);
    }

    /**
     * @dev Overridden operatorSend function to include KYC and restriction checks.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) public override onlyKYCApproved(sender) notRestricted(sender) notRestricted(recipient) {
        super.operatorSend(sender, recipient, amount, data, operatorData);
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
