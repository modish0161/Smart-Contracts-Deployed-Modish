// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Batch Transfer Contract for Real Assets
/// @notice Facilitates batch transfers of multiple real assets in a single transaction, reducing transaction costs and improving efficiency for large portfolios of tokenized real assets.
/// @dev Uses the ERC1155 standard to manage multiple assets within a single contract.
contract BatchTransferRealAssets is ERC1155, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    // Mapping to store asset information
    struct Asset {
        uint256 id;
        string name;
        uint256 totalSupply;
    }
    mapping(uint256 => Asset) private _assets;

    // Events
    event AssetTokenized(uint256 indexed assetId, string name, uint256 totalSupply);
    event BatchTransfer(
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );
    event AssetMinted(uint256 indexed assetId, address indexed to, uint256 amount);
    event AssetBurned(uint256 indexed assetId, address indexed from, uint256 amount);

    /// @dev Constructor to set up the initial values and roles
    /// @param uri Base URI for all token types
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ASSET_MANAGER_ROLE, msg.sender);
    }

    /// @notice Function to create a new asset
    /// @param name Name of the asset (e.g., Gold, Silver, Property)
    /// @param totalSupply Total supply of the asset tokens
    /// @param uri Metadata URI for the asset token
    /// @dev Only an account with the ASSET_MANAGER_ROLE can call this function
    function tokenizeAsset(
        string memory name,
        uint256 totalSupply,
        string memory uri
    ) external onlyRole(ASSET_MANAGER_ROLE) whenNotPaused {
        uint256 assetId = _generateAssetId(name);
        _setURI(uri);
        _assets[assetId] = Asset(assetId, name, totalSupply);

        emit AssetTokenized(assetId, name, totalSupply);
    }

    /// @notice Function to mint tokens for an asset
    /// @param to Address to mint tokens to
    /// @param assetId ID of the asset to mint
    /// @param amount Amount of tokens to mint
    /// @dev Only an account with the ASSET_MANAGER_ROLE can call this function
    function mintAsset(
        address to,
        uint256 assetId,
        uint256 amount
    ) external onlyRole(ASSET_MANAGER_ROLE) whenNotPaused {
        require(_assets[assetId].totalSupply > 0, "Asset does not exist");
        _mint(to, assetId, amount, "");
        emit AssetMinted(assetId, to, amount);
    }

    /// @notice Function to burn tokens of an asset
    /// @param from Address to burn tokens from
    /// @param assetId ID of the asset to burn
    /// @param amount Amount of tokens to burn
    /// @dev Only an account with the ASSET_MANAGER_ROLE can call this function
    function burnAsset(
        address from,
        uint256 assetId,
        uint256 amount
    ) external onlyRole(ASSET_MANAGER_ROLE) whenNotPaused {
        require(_assets[assetId].totalSupply > 0, "Asset does not exist");
        _burn(from, assetId, amount);
        emit AssetBurned(assetId, from, amount);
    }

    /// @notice Function to transfer multiple assets in a single transaction
    /// @param from Address to transfer assets from
    /// @param to Address to transfer assets to
    /// @param ids Array of asset IDs to transfer
    /// @param amounts Array of amounts to transfer for each asset ID
    /// @dev Can be called by any user with sufficient balances of the token
    function batchTransfer(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused {
        require(ids.length == amounts.length, "Mismatched asset IDs and amounts");
        for (uint256 i = 0; i < ids.length; i++) {
            require(balanceOf(from, ids[i]) >= amounts[i], "Insufficient balance to transfer");
        }
        safeBatchTransferFrom(from, to, ids, amounts, "");
        emit BatchTransfer(from, to, ids, amounts);
    }

    /// @notice Function to get asset details
    /// @param assetId ID of the asset token
    /// @return Asset structure with all details
    function getAssetDetails(uint256 assetId) external view returns (Asset memory) {
        require(_assets[assetId].totalSupply > 0, "Asset does not exist");
        return _assets[assetId];
    }

    /// @notice Function to withdraw funds from the contract
    /// @dev Only the owner can withdraw the funds
    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
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

    /// @dev Internal function to generate a unique asset ID based on the name
    /// @param name Name of the asset
    /// @return uint256 Unique asset ID
    function _generateAssetId(string memory name) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(name)));
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
