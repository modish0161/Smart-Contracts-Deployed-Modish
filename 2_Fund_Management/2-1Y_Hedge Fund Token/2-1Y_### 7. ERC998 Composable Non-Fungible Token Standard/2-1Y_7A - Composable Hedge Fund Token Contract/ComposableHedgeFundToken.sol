// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ComposableHedgeFundToken is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Asset {
        address assetAddress; // Address of the token contract
        uint256 assetId;      // Asset ID if ERC721, or amount if ERC20
        uint256 amount;       // Amount for fungible assets
    }

    mapping(uint256 => Asset[]) public tokenAssets; // Mapping from token ID to its assets

    event AssetAdded(uint256 indexed tokenId, address indexed assetAddress, uint256 assetId, uint256 amount);
    event AssetRemoved(uint256 indexed tokenId, address indexed assetAddress, uint256 assetId, uint256 amount);

    constructor() ERC721("Composable Hedge Fund Token", "CHFT") {}

    // Mint a new composable token
    function mint() external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId);
        _tokenIdCounter.increment();
    }

    // Add asset to a token
    function addAsset(uint256 tokenId, address assetAddress, uint256 assetId, uint256 amount) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        tokenAssets[tokenId].push(Asset(assetAddress, assetId, amount));
        emit AssetAdded(tokenId, assetAddress, assetId, amount);
    }

    // Remove asset from a token
    function removeAsset(uint256 tokenId, uint256 assetIndex) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        require(assetIndex < tokenAssets[tokenId].length, "Invalid asset index");

        Asset memory asset = tokenAssets[tokenId][assetIndex];

        // Remove asset from the array
        tokenAssets[tokenId][assetIndex] = tokenAssets[tokenId][tokenAssets[tokenId].length - 1];
        tokenAssets[tokenId].pop();

        emit AssetRemoved(tokenId, asset.assetAddress, asset.assetId, asset.amount);
    }

    // Get all assets for a specific token
    function getAssets(uint256 tokenId) external view returns (Asset[] memory) {
        return tokenAssets[tokenId];
    }

    // Override the _baseURI function if needed for metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://api.yourdomain.com/tokens/";
    }
}
