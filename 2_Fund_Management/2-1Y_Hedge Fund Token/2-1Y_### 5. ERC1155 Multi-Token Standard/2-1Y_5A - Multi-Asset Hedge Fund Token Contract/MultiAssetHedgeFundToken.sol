// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MultiAssetHedgeFundToken is ERC1155, Ownable, ReentrancyGuard {
    // Mapping to track asset prices
    mapping(uint256 => uint256) public assetPrices; 
    mapping(uint256 => string) public assetNames; 
    mapping(uint256 => uint256) public totalSupply; 

    event AssetAdded(uint256 indexed id, string name, uint256 price);
    event AssetPriceUpdated(uint256 indexed id, uint256 newPrice);
    event TokensMinted(address indexed investor, uint256 indexed id, uint256 amount);
    event TokensBurned(address indexed investor, uint256 indexed id, uint256 amount);

    constructor() ERC1155("https://api.example.com/metadata/{id}.json") {}

    // Function to add a new asset
    function addAsset(uint256 id, string memory name, uint256 price) external onlyOwner {
        require(assetPrices[id] == 0, "Asset already exists");
        assetPrices[id] = price;
        assetNames[id] = name;
        emit AssetAdded(id, name, price);
    }

    // Function to update asset price
    function updateAssetPrice(uint256 id, uint256 newPrice) external onlyOwner {
        require(assetPrices[id] > 0, "Asset does not exist");
        assetPrices[id] = newPrice;
        emit AssetPriceUpdated(id, newPrice);
    }

    // Function to mint new tokens for a specific asset
    function mintTokens(uint256 id, uint256 amount) external nonReentrant {
        require(assetPrices[id] > 0, "Asset does not exist");
        _mint(msg.sender, id, amount, ""); // Mint tokens for the specified asset
        totalSupply[id] += amount;
        emit TokensMinted(msg.sender, id, amount);
    }

    // Function to burn tokens for a specific asset
    function burnTokens(uint256 id, uint256 amount) external nonReentrant {
        require(totalSupply[id] >= amount, "Not enough tokens to burn");
        _burn(msg.sender, id, amount); // Burn tokens for the specified asset
        totalSupply[id] -= amount;
        emit TokensBurned(msg.sender, id, amount);
    }

    // Function to get asset details
    function getAssetDetails(uint256 id) external view returns (string memory name, uint256 price, uint256 supply) {
        name = assetNames[id];
        price = assetPrices[id];
        supply = totalSupply[id];
    }
}
