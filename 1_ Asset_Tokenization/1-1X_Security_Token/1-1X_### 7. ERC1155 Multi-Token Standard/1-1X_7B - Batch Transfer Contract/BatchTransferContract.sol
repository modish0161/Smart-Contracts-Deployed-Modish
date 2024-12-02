// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Batch Transfer Contract for Multiple Asset Types
/// @dev ERC1155 contract for managing batch transfers of multiple types of tokenized assets within a single contract.
contract BatchTransferContract is ERC1155, ERC1155Supply, Ownable, AccessControl, Pausable, ReentrancyGuard {
    
    // Role definitions for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BATCH_TRANSFER_ROLE = keccak256("BATCH_TRANSFER_ROLE");

    /// @dev Event emitted when tokens are transferred in a batch
    event BatchTransferExecuted(address indexed operator, address[] recipients, uint256[] ids, uint256[] amounts);

    /// @notice Constructor to initialize the contract with a base URI
    /// @param baseUri Initial base URI for all tokens
    constructor(string memory baseUri) ERC1155(baseUri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(BATCH_TRANSFER_ROLE, msg.sender);
    }

    /// @notice Mint new tokens for a specific asset type
    /// @dev Only accounts with the MINTER_ROLE can mint new tokens
    /// @param to Address of the token recipient
    /// @param id ID of the asset type to mint
    /// @param amount Amount of tokens to mint
    /// @param data Additional data to pass to the transfer
    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    /// @notice Mint new tokens in batch for multiple asset types
    /// @dev Only accounts with the MINTER_ROLE can mint new tokens in batch
    /// @param to Address of the token recipient
    /// @param ids Array of asset type IDs to mint
    /// @param amounts Array of amounts of tokens to mint
    /// @param data Additional data to pass to the transfer
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /// @notice Batch transfer tokens to multiple recipients
    /// @dev Only accounts with the BATCH_TRANSFER_ROLE can perform batch transfers
    /// @param recipients Array of addresses to receive the tokens
    /// @param ids Array of token IDs to transfer
    /// @param amounts Array of amounts of tokens to transfer
    /// @param data Additional data to pass to the transfer
    function batchTransfer(address[] memory recipients, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(BATCH_TRANSFER_ROLE) nonReentrant {
        require(recipients.length == ids.length && ids.length == amounts.length, "BatchTransferContract: recipients, ids, and amounts length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "BatchTransferContract: transfer to the zero address");
            safeTransferFrom(_msgSender(), recipients[i], ids[i], amounts[i], data);
        }

        emit BatchTransferExecuted(_msgSender(), recipients, ids, amounts);
    }

    /// @notice Pauses all token transfers
    /// @dev Only accounts with the PAUSER_ROLE can pause the contract
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses all token transfers
    /// @dev Only accounts with the PAUSER_ROLE can unpause the contract
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Override _beforeTokenTransfer to include only allowed transfers
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @notice Override supportsInterface to include additional interfaces
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Add a new minter with the MINTER_ROLE
    /// @param account Address to be granted the minter role
    function addMinter(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    /// @notice Remove an existing minter with the MINTER_ROLE
    /// @param account Address to be revoked the minter role
    function removeMinter(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }

    /// @notice Add a new pauser with the PAUSER_ROLE
    /// @param account Address to be granted the pauser role
    function addPauser(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(PAUSER_ROLE, account);
    }

    /// @notice Remove an existing pauser with the PAUSER_ROLE
    /// @param account Address to be revoked the pauser role
    function removePauser(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(PAUSER_ROLE, account);
    }

    /// @notice Add a new batch transfer operator with the BATCH_TRANSFER_ROLE
    /// @param account Address to be granted the batch transfer role
    function addBatchTransferOperator(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(BATCH_TRANSFER_ROLE, account);
    }

    /// @notice Remove an existing batch transfer operator with the BATCH_TRANSFER_ROLE
    /// @param account Address to be revoked the batch transfer role
    function removeBatchTransferOperator(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(BATCH_TRANSFER_ROLE, account);
    }
}
