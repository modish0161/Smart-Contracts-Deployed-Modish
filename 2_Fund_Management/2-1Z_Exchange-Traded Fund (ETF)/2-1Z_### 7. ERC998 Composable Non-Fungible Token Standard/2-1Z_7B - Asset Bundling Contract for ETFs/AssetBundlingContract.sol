// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998.sol";

contract AssetBundlingContract is ERC998, Ownable {
    // Mapping from token ID to its assets
    mapping(uint256 => address[]) private _bundledAssets; // Array of asset contracts
    mapping(uint256 => uint256[]) private _assetIds;      // Array of asset IDs

    // Events
    event AssetsBundled(uint256 indexed tokenId, address[] assetContracts, uint256[] assetIds);
    event AssetsUnbundled(uint256 indexed tokenId, address[] assetContracts, uint256[] assetIds);

    constructor() ERC721("Asset Bundling Token", "ABT") {}

    // Create a new bundling token
    function createBundleToken() external onlyOwner returns (uint256) {
        uint256 tokenId = totalSupply(); // Use totalSupply to get a new token ID
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    // Bundle multiple assets into a single token
    function bundleAssets(uint256 tokenId, address[] memory assetContracts, uint256[] memory assetIds) external onlyOwner {
        require(assetContracts.length == assetIds.length, "Mismatched input lengths");
        
        for (uint256 i = 0; i < assetContracts.length; i++) {
            _bundledAssets[tokenId].push(assetContracts[i]);
            _assetIds[tokenId].push(assetIds[i]);
        }
        
        emit AssetsBundled(tokenId, assetContracts, assetIds);
    }

    // Unbundle assets from a token
    function unbundleAssets(uint256 tokenId) external onlyOwner {
        address[] memory assetContracts = _bundledAssets[tokenId];
        uint256[] memory assetIds = _assetIds[tokenId];

        delete _bundledAssets[tokenId];
        delete _assetIds[tokenId];

        emit AssetsUnbundled(tokenId, assetContracts, assetIds);
    }

    // Get the bundled assets for a token
    function getBundledAssets(uint256 tokenId) external view returns (address[] memory, uint256[] memory) {
        return (_bundledAssets[tokenId], _assetIds[tokenId]);
    }

    // Override required functions for ERC998
    function onERC721Received(address, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address from, uint256 id, uint256 value, bytes memory data) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
