// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Real Estate Portfolio Tokenization Contract
/// @notice This contract tokenizes a portfolio of real estate assets, where each token can represent an entire property or fractional ownership in multiple properties.
/// @dev Uses the ERC1155 standard to manage a diverse portfolio of real estate tokens.
contract RealEstatePortfolioTokenization is ERC1155, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    // Counter for token IDs
    Counters.Counter private _tokenIdCounter;

    // Mapping to store asset information
    struct Asset {
        uint256 id;
        string name;
        string location;
        uint256 valuation;
        uint256 totalSupply;
    }
    mapping(uint256 => Asset) private _assets;

    // Events
    event AssetTokenized(uint256 indexed tokenId, string name, string location, uint256 valuation, uint256 totalSupply);
    event AssetMinted(uint256 indexed tokenId, address indexed to, uint256 amount);
    event AssetBurned(uint256 indexed tokenId, address indexed from, uint256 amount);
    event AssetTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);

    /// @dev Constructor to set up the initial values and roles
    /// @param uri Base URI for all token types
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ASSET_MANAGER_ROLE, msg.sender);
    }

    /// @notice Function to create a new asset
    /// @param name Name of the real estate asset
    /// @param location Location of the property
    /// @param valuation Valuation of the asset in the desired currency (e.g., USD)
    /// @param totalSupply Total supply of the asset tokens
    /// @param uri Metadata URI for the asset token
    /// @dev Only an account with the ASSET_MANAGER_ROLE can call this function
    function tokenizeAsset(
        string memory name,
        string memory location,
        uint256 valuation,
        uint256 totalSupply,
        string memory uri
    ) external onlyRole(ASSET_MANAGER_ROLE) whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _setURI(uri);
        _assets[tokenId] = Asset(tokenId, name, location, valuation, totalSupply);

        emit AssetTokenized(tokenId, name, location, valuation, totalSupply);
    }

    /// @notice Function to mint tokens for an asset
    /// @param to Address to mint tokens to
    /// @param tokenId ID of the token to mint
    /// @param amount Amount of tokens to mint
    /// @dev Only an account with the ASSET_MANAGER_ROLE can call this function
    function mintAsset(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(ASSET_MANAGER_ROLE) whenNotPaused {
        require(_assets[tokenId].totalSupply > 0, "Asset does not exist");
        _mint(to, tokenId, amount, "");
        emit AssetMinted(tokenId, to, amount);
    }

    /// @notice Function to burn tokens of an asset
    /// @param from Address to burn tokens from
    /// @param tokenId ID of the token to burn
    /// @param amount Amount of tokens to burn
    /// @dev Only an account with the ASSET_MANAGER_ROLE can call this function
    function burnAsset(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(ASSET_MANAGER_ROLE) whenNotPaused {
        require(_assets[tokenId].totalSupply > 0, "Asset does not exist");
        _burn(from, tokenId, amount);
        emit AssetBurned(tokenId, from, amount);
    }

    /// @notice Function to transfer tokens of an asset
    /// @param from Address to transfer tokens from
    /// @param to Address to transfer tokens to
    /// @param tokenId ID of the token to transfer
    /// @param amount Amount of tokens to transfer
    /// @dev Can be called by any user with sufficient balance of the token
    function transferAsset(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        require(balanceOf(from, tokenId) >= amount, "Insufficient balance to transfer");
        safeTransferFrom(from, to, tokenId, amount, "");
        emit AssetTransferred(tokenId, from, to, amount);
    }

    /// @notice Function to get asset details
    /// @param tokenId ID of the asset token
    /// @return Asset structure with all details
    function getAssetDetails(uint256 tokenId) external view returns (Asset memory) {
        require(_assets[tokenId].totalSupply > 0, "Asset does not exist");
        return _assets[tokenId];
    }

    /// @notice Function to pause the contract
    /// @dev Only accounts with ADMIN_ROLE can pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Function to unpause the contract
    /// @dev Only accounts with ADMIN_ROLE can unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
