// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BasicKYCAMLComplianceContract is ERC20, Ownable, Pausable, ReentrancyGuard, AccessControl {
    
    // Role for KYC and AML verifiers
    bytes32 public constant KYC_VERIFIER_ROLE = keccak256("KYC_VERIFIER_ROLE");

    // Mapping to track KYC status of users
    mapping(address => bool) private _kycApproved;

    // Events for KYC Approval
    event KYCApproved(address indexed user);
    event KYCRevoked(address indexed user);

    // Modifier to restrict actions to KYC-approved addresses only
    modifier onlyKYCApproved(address _user) {
        require(_kycApproved[_user], "User is not KYC approved");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _kycVerifier
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(KYC_VERIFIER_ROLE, _kycVerifier);
    }

    /**
     * @dev Approves KYC for a user
     * @param user Address to be KYC approved
     */
    function approveKYC(address user) external onlyRole(KYC_VERIFIER_ROLE) {
        _kycApproved[user] = true;
        emit KYCApproved(user);
    }

    /**
     * @dev Revokes KYC for a user
     * @param user Address to be KYC revoked
     */
    function revokeKYC(address user) external onlyRole(KYC_VERIFIER_ROLE) {
        _kycApproved[user] = false;
        emit KYCRevoked(user);
    }

    /**
     * @dev Checks if a user is KYC approved
     * @param user Address to check KYC status
     * @return true if the user is KYC approved, false otherwise
     */
    function isKYCApproved(address user) external view returns (bool) {
        return _kycApproved[user];
    }

    /**
     * @dev Overrides the ERC20 transfer function to include KYC check
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function transfer(address recipient, uint256 amount) public override onlyKYCApproved(msg.sender) onlyKYCApproved(recipient) returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @dev Overrides the ERC20 transferFrom function to include KYC check
     * @param sender Address of the sender
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override onlyKYCApproved(sender) onlyKYCApproved(recipient) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Mint function with KYC and onlyOwner checks
     * @param account Address to receive the tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address account, uint256 amount) external onlyOwner onlyKYCApproved(account) {
        _mint(account, amount);
    }

    /**
     * @dev Function to pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Function to unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Burn function for the owner to burn tokens
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Internal function to include pause checks on token transfers
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
