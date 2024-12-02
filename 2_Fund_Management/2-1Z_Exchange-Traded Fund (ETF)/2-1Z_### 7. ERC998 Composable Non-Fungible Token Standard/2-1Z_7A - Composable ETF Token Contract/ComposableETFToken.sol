// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998.sol";

contract ComposableETFToken is ERC998, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Asset data structure
    struct Asset {
        address assetContract; // Address of the asset contract (e.g., ERC20 or ERC721)
        uint256 assetId;       // Asset ID (for ERC721) or amount (for ERC20)
        uint256 amount;        // Amount of the asset (for ERC20)
    }

    // Mapping from token ID to its assets
    mapping(uint256 => Asset[]) private _assets;

    // Events
    event AssetsAdded(uint256 indexed tokenId, address assetContract, uint256 assetId, uint256 amount);
    event AssetsRemoved(uint256 indexed tokenId, address assetContract, uint256 assetId, uint256 amount);

    constructor() ERC721("Composable ETF Token", "CETF") {}

    // Create a new ETF token
    function createETFTokens() external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId);
        _tokenIdCounter.increment();
        return tokenId;
    }

    // Add assets to a specific ETF token
    function addAsset(uint256 tokenId, address assetContract, uint256 assetId, uint256 amount) external onlyOwner {
        _assets[tokenId].push(Asset(assetContract, assetId, amount));
        emit AssetsAdded(tokenId, assetContract, assetId, amount);
    }

    // Remove assets from a specific ETF token
    function removeAsset(uint256 tokenId, address assetContract, uint256 assetId, uint256 amount) external onlyOwner {
        Asset[] storage assets = _assets[tokenId];
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].assetContract == assetContract && assets[i].assetId == assetId && assets[i].amount >= amount) {
                assets[i].amount -= amount;
                emit AssetsRemoved(tokenId, assetContract, assetId, amount);
                return;
            }
        }
        revert("Asset not found or insufficient amount");
    }

    // Get assets associated with a specific ETF token
    function getAssets(uint256 tokenId) external view returns (Asset[] memory) {
        return _assets[tokenId];
    }

    // Override required functions for ERC998
    function onERC721Received(address, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        // Custom logic for receiving ERC721 tokens can be implemented here
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address from, uint256 id, uint256 value, bytes memory data) public virtual override returns (bytes4) {
        // Custom logic for receiving ERC1155 tokens can be implemented here
        return this.onERC1155Received.selector;
    }
}
