// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Tokenized Securities Vault Contract
/// @dev This contract represents pools of tokenized securities like stocks, bonds, and real estate,
///      allowing investors to gain exposure to multiple tokenized assets through a single vault token.
///      It adheres to the ERC4626 standard for tokenized vaults.
contract TokenizedSecuritiesVault is ERC4626, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Role definitions for access control
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Constructor to initialize the vault with underlying ERC20 token
    /// @param asset Address of the underlying ERC20 token (e.g., a stablecoin or security token)
    /// @param name Name of the vault token
    /// @param symbol Symbol of the vault token
    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Pauses all deposit, withdraw, and transfer actions
    /// @dev Only accounts with the PAUSER_ROLE can pause the contract
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses all deposit, withdraw, and transfer actions
    /// @dev Only accounts with the PAUSER_ROLE can unpause the contract
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Deposits assets into the vault
    /// @dev Overrides the deposit function from ERC4626 to add pausable and non-reentrant modifiers
    function deposit(uint256 assets, address receiver) public override whenNotPaused nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /// @notice Withdraws assets from the vault
    /// @dev Overrides the withdraw function from ERC4626 to add pausable and non-reentrant modifiers
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused nonReentrant returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /// @notice Adds an admin to the contract with ADMIN_ROLE
    /// @param account Address to be granted the admin role
    function addAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
    }

    /// @notice Removes an existing admin from the contract
    /// @param account Address to be revoked the admin role
    function removeAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, account);
    }

    /// @notice Adds a pauser to the contract with PAUSER_ROLE
    /// @param account Address to be granted the pauser role
    function addPauser(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(PAUSER_ROLE, account);
    }

    /// @notice Removes an existing pauser from the contract
    /// @param account Address to be revoked the pauser role
    function removePauser(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(PAUSER_ROLE, account);
    }

    /// @notice Override _beforeTokenTransfer to include pausable functionality
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @notice Override supportsInterface to include additional interfaces
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC4626) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
