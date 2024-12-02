// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BatchTransferHedgeFundToken is ERC1155, Ownable, ReentrancyGuard {
    // Mapping to track asset prices and names
    mapping(uint256 => uint256) public assetPrices; 
    mapping(uint256 => string) public assetNames; 
    mapping(uint256 => uint256) public totalSupply; 

    event AssetAdded(uint256 indexed id, string name, uint256 price);
    event TokensMinted(address indexed investor, uint256[] indexed ids, uint256[] amounts);
    event TokensBurned(address indexed investor, uint256[] indexed ids, uint256[] amounts);
    event BatchTransfer(address indexed from, address indexed to, uint256[] indexed ids, uint256[] amounts);

    constructor() ERC1155("https://api.example.com/metadata/{id}.json") {}

    // Function to add a new asset
    function addAsset(uint256 id, string memory name, uint256 price) external onlyOwner {
        require(assetPrices[id] == 0, "Asset already exists");
        assetPrices[id] = price;
        assetNames[id] = name;
        emit AssetAdded(id, name, price);
    }

    // Function to mint new tokens for multiple assets
    function mintTokens(uint256[] memory ids, uint256[] memory amounts) external nonReentrant {
        require(ids.length == amounts.length, "IDs and amounts must match");
        for (uint256 i = 0; i < ids.length; i++) {
            require(assetPrices[ids[i]] > 0, "Asset does not exist");
            totalSupply[ids[i]] += amounts[i];
        }
        _mintBatch(msg.sender, ids, amounts, ""); // Mint tokens for multiple assets
        emit TokensMinted(msg.sender, ids, amounts);
    }

    // Function to burn tokens for multiple assets
    function burnTokens(uint256[] memory ids, uint256[] memory amounts) external nonReentrant {
        require(ids.length == amounts.length, "IDs and amounts must match");
        for (uint256 i = 0; i < ids.length; i++) {
            require(totalSupply[ids[i]] >= amounts[i], "Not enough tokens to burn");
            totalSupply[ids[i]] -= amounts[i];
        }
        _burnBatch(msg.sender, ids, amounts); // Burn tokens for multiple assets
        emit TokensBurned(msg.sender, ids, amounts);
    }

    // Function to batch transfer tokens to another address
    function batchTransfer(address to, uint256[] memory ids, uint256[] memory amounts) external nonReentrant {
        require(ids.length == amounts.length, "IDs and amounts must match");
        safeBatchTransferFrom(msg.sender, to, ids, amounts, ""); // Batch transfer tokens
        emit BatchTransfer(msg.sender, to, ids, amounts);
    }

    // Function to get asset details
    function getAssetDetails(uint256 id) external view returns (string memory name, uint256 price, uint256 supply) {
        name = assetNames[id];
        price = assetPrices[id];
        supply = totalSupply[id];
    }
}
