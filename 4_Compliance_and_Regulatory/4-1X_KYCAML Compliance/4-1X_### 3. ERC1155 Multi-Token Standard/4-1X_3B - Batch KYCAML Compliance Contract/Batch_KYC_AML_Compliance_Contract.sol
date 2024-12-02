// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BatchKYCAMLComplianceContract is ERC1155, Ownable, AccessControl, Pausable, ReentrancyGuard {

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

    // Event to log batch KYC approval
    event BatchKYCApproved(address[] indexed users);

    // Event to log batch KYC revocation
    event BatchKYCRevoked(address[] indexed users);

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
        string memory uri,
        address complianceOfficer
    ) ERC1155(uri) {
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
     * @dev Approves KYC for multiple users in a batch.
     * @param users Array of addresses to approve KYC.
     */
    function approveKYCInBatch(address[] calldata users) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            _kycApproved[users[i]] = true;
        }
        emit BatchKYCApproved(users);
    }

    /**
     * @dev Revokes KYC for multiple users in a batch.
     * @param users Array of addresses to revoke KYC.
     */
    function revokeKYCInBatch(address[] calldata users) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            _kycApproved[users[i]] = false;
        }
        emit BatchKYCRevoked(users);
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
     * @dev Overridden safeTransferFrom function to include KYC and restriction checks.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyKYCApproved(from) notRestricted(from) notRestricted(to) whenNotPaused {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Overridden safeBatchTransferFrom function to include KYC and restriction checks.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyKYCApproved(from) notRestricted(from) notRestricted(to) whenNotPaused {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Mint new tokens with KYC and restriction checks.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyKYCApproved(account) notRestricted(account) {
        _mint(account, id, amount, data);
    }

    /**
     * @dev Mint multiple tokens with KYC and restriction checks.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyKYCApproved(to) notRestricted(to) {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Burn tokens with KYC and restriction checks.
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyKYCApproved(account) notRestricted(account) {
        _burn(account, id, amount);
    }

    /**
     * @dev Burn multiple tokens with KYC and restriction checks.
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyKYCApproved(account) notRestricted(account) {
        _burnBatch(account, ids, amounts);
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
