// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

contract VaultKYCAMLCompliance is ERC4626, Ownable, AccessControl, Pausable {
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // Mapping for KYC-approved users
    mapping(address => bool) private _kycApproved;

    // Mapping for restricted users (e.g., users who failed KYC/AML checks)
    mapping(address => bool) private _restricted;

    // Event for KYC approval
    event KYCApproved(address indexed user);

    // Event for KYC revocation
    event KYCRevoked(address indexed user);

    // Event for compliance restriction applied
    event ComplianceRestrictionApplied(address indexed user, string reason);

    // Event for compliance restriction removed
    event ComplianceRestrictionRemoved(address indexed user);

    // Modifier to ensure only KYC-approved and unrestricted users can interact with the vault
    modifier onlyCompliant(address user) {
        require(_kycApproved[user], "User is not KYC approved");
        require(!_restricted[user], "User is restricted by compliance");
        _;
    }

    constructor(
        IERC20 _asset,
        string memory name_,
        string memory symbol_,
        address complianceOfficer
    ) ERC4626(_asset) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, complianceOfficer);

        // Set ERC4626 metadata
        _setMetadata(name_, symbol_);
    }

    /**
     * @dev Approve KYC for a user.
     * @param user Address of the user to approve.
     */
    function approveKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = true;
        emit KYCApproved(user);
    }

    /**
     * @dev Revoke KYC for a user.
     * @param user Address of the user to revoke.
     */
    function revokeKYC(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _kycApproved[user] = false;
        emit KYCRevoked(user);
    }

    /**
     * @dev Apply compliance restriction to a user.
     * @param user Address of the user to restrict.
     * @param reason Reason for restriction.
     */
    function applyComplianceRestriction(address user, string calldata reason) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[user] = true;
        emit ComplianceRestrictionApplied(user, reason);
    }

    /**
     * @dev Remove compliance restriction from a user.
     * @param user Address of the user to remove restriction.
     */
    function removeComplianceRestriction(address user) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[user] = false;
        emit ComplianceRestrictionRemoved(user);
    }

    /**
     * @dev Check if a user is KYC-approved.
     * @param user Address to check.
     * @return true if the user is KYC-approved, false otherwise.
     */
    function isKYCApproved(address user) public view returns (bool) {
        return _kycApproved[user];
    }

    /**
     * @dev Check if a user is restricted by compliance.
     * @param user Address to check.
     * @return true if the user is restricted, false otherwise.
     */
    function isRestricted(address user) public view returns (bool) {
        return _restricted[user];
    }

    /**
     * @dev Override deposit function to include KYC/AML compliance checks.
     * @param assets Amount of assets to deposit.
     * @param receiver Address of the receiver of the shares.
     */
    function deposit(uint256 assets, address receiver) public override onlyCompliant(receiver) whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /**
     * @dev Override withdraw function to include KYC/AML compliance checks.
     * @param assets Amount of assets to withdraw.
     * @param receiver Address of the receiver of the assets.
     * @param owner Address of the owner of the shares.
     */
    function withdraw(uint256 assets, address receiver, address owner) public override onlyCompliant(owner) whenNotPaused returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @dev Override mint function to include KYC/AML compliance checks.
     * @param shares Amount of shares to mint.
     * @param receiver Address of the receiver of the shares.
     */
    function mint(uint256 shares, address receiver) public override onlyCompliant(receiver) whenNotPaused returns (uint256) {
        return super.mint(shares, receiver);
    }

    /**
     * @dev Override redeem function to include KYC/AML compliance checks.
     * @param shares Amount of shares to redeem.
     * @param receiver Address of the receiver of the assets.
     * @param owner Address of the owner of the shares.
     */
    function redeem(uint256 shares, address receiver, address owner) public override onlyCompliant(owner) whenNotPaused returns (uint256) {
        return super.redeem(shares, receiver, owner);
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
