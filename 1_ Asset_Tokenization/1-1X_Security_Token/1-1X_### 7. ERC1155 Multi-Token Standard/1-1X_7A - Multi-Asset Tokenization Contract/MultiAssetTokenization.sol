// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Multi-Asset Tokenization Contract
/// @dev ERC1155 contract for managing multiple types of tokenized assets within a single contract.
contract MultiAssetTokenization is ERC1155, ERC1155Supply, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Role definitions for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Token metadata mapping
    mapping(uint256 => string) private _tokenURIs;

    /// @dev Event emitted when a new asset type is created
    event AssetTypeCreated(uint256 indexed tokenId, string uri);

    /// @dev Event emitted when tokens are minted
    event TokensMinted(address indexed to, uint256 indexed tokenId, uint256 amount);

    /// @dev Event emitted when tokens are burned
    event TokensBurned(address indexed from, uint256 indexed tokenId, uint256 amount);

    /// @notice Constructor to initialize the contract with a base URI
    /// @param baseUri Initial base URI for all tokens
    constructor(string memory baseUri) ERC1155(baseUri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice Create a new asset type
    /// @dev Only accounts with the MINTER_ROLE can create new asset types
    /// @param uri URI for the new asset type metadata
    /// @return tokenId The ID of the newly created asset type
    function createAssetType(string memory uri) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _tokenURIs[tokenId] = uri;
        
        emit AssetTypeCreated(tokenId, uri);
        return tokenId;
    }

    /// @notice Mint new tokens for a specific asset type
    /// @dev Only accounts with the MINTER_ROLE can mint new tokens
    /// @param to Address of the token recipient
    /// @param tokenId ID of the asset type to mint
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 tokenId, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(exists(tokenId), "MultiAssetTokenization: tokenId does not exist");
        _mint(to, tokenId, amount, "");
        emit TokensMinted(to, tokenId, amount);
    }

    /// @notice Burn tokens of a specific asset type
    /// @dev Only the token holder or approved account can burn tokens
    /// @param from Address of the token holder
    /// @param tokenId ID of the asset type to burn
    /// @param amount Amount of tokens to burn
    function burn(address from, uint256 tokenId, uint256 amount) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "MultiAssetTokenization: caller is not owner nor approved"
        );
        require(balanceOf(from, tokenId) >= amount, "MultiAssetTokenization: burn amount exceeds balance");

        _burn(from, tokenId, amount);
        emit TokensBurned(from, tokenId, amount);
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

    /// @notice Get the URI of a specific token ID
    /// @param tokenId ID of the asset type
    /// @return URI of the specified token ID
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "MultiAssetTokenization: URI query for nonexistent token");
        return _tokenURIs[tokenId];
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
    function addMinter(address account) public onlyRole(ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    /// @notice Remove an existing minter with the MINTER_ROLE
    /// @param account Address to be revoked the minter role
    function removeMinter(address account) public onlyRole(ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }

    /// @notice Add a new pauser with the PAUSER_ROLE
    /// @param account Address to be granted the pauser role
    function addPauser(address account) public onlyRole(ADMIN_ROLE) {
        grantRole(PAUSER_ROLE, account);
    }

    /// @notice Remove an existing pauser with the PAUSER_ROLE
    /// @param account Address to be revoked the pauser role
    function removePauser(address account) public onlyRole(ADMIN_ROLE) {
        revokeRole(PAUSER_ROLE, account);
    }

    /// @notice Add a new admin with the ADMIN_ROLE
    /// @param account Address to be granted the admin role
    function addAdmin(address account) public onlyRole(ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
    }

    /// @notice Remove an existing admin with the ADMIN_ROLE
    /// @param account Address to be revoked the admin role
    function removeAdmin(address account) public onlyRole(ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, account);
    }
}
