// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Unique Asset Tokenization Contract
/// @notice This contract tokenizes unique physical assets such as artwork, collectible cars, or luxury goods, using the ERC721 standard.
/// @dev Each ERC721 token represents a unique physical item stored in a secure location.
contract UniqueAssetTokenization is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, AccessControl, ReentrancyGuard {
    using Strings for uint256;

    // Counter for token IDs
    uint256 private _tokenIdCounter;

    // Role for asset verifiers
    bytes32 public constant ASSET_VERIFIER_ROLE = keccak256("ASSET_VERIFIER_ROLE");

    // Structure to hold asset details
    struct Asset {
        uint256 id;
        string name;
        string description;
        string serialNumber;
        string location;
        uint256 valuation;
        bool isForSale;
        uint256 price;
    }

    // Mapping from token ID to Asset details
    mapping(uint256 => Asset) private _assets;

    // Events
    event AssetTokenized(uint256 indexed tokenId, address indexed owner, string name, string serialNumber, string location, uint256 valuation);
    event AssetForSale(uint256 indexed tokenId, uint256 price);
    event AssetSold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    /// @dev Constructor to initialize the ERC721 contract with name and symbol
    constructor() ERC721("UniqueAssetToken", "UAT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ASSET_VERIFIER_ROLE, msg.sender);
    }

    /// @notice Function to tokenize a new asset
    /// @param to Address of the token owner
    /// @param name The name of the asset
    /// @param description The description of the asset
    /// @param serialNumber The unique serial number of the asset
    /// @param location The location where the asset is stored
    /// @param valuation The valuation of the asset in the desired currency
    /// @param uri Metadata URI for the asset token
    /// @dev Only accounts with the ASSET_VERIFIER_ROLE can call this function
    function tokenizeAsset(
        address to,
        string memory name,
        string memory description,
        string memory serialNumber,
        string memory location,
        uint256 valuation,
        string memory uri
    ) external onlyRole(ASSET_VERIFIER_ROLE) nonReentrant {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);

        _assets[tokenId] = Asset(tokenId, name, description, serialNumber, location, valuation, false, 0);
        emit AssetTokenized(tokenId, to, name, serialNumber, location, valuation);
    }

    /// @notice Function to set an asset for sale
    /// @param tokenId The ID of the asset token
    /// @param salePrice The sale price of the asset
    /// @dev Only the owner of the token can set it for sale
    function setAssetForSale(uint256 tokenId, uint256 salePrice) external onlyOwnerOf(tokenId) {
        require(_assets[tokenId].isForSale == false, "Asset is already for sale");
        _assets[tokenId].isForSale = true;
        _assets[tokenId].price = salePrice;

        emit AssetForSale(tokenId, salePrice);
    }

    /// @notice Function to purchase an asset that is for sale
    /// @param tokenId The ID of the asset token to be purchased
    /// @dev The buyer must send the exact sale price to the contract
    function purchaseAsset(uint256 tokenId) external payable nonReentrant {
        Asset memory asset = _assets[tokenId];
        require(asset.isForSale, "Asset is not for sale");
        require(msg.value == asset.price, "Incorrect value sent");

        address seller = ownerOf(tokenId);
        _assets[tokenId].isForSale = false;

        _transfer(seller, msg.sender, tokenId);
        payable(seller).transfer(msg.value);

        emit AssetSold(tokenId, msg.sender, msg.value);
    }

    /// @notice Function to get the details of an asset
    /// @param tokenId The ID of the asset token
    /// @return Asset details including id, name, description, serial number, location, valuation, price, and sale status
    function getAssetDetails(uint256 tokenId) external view returns (Asset memory) {
        return _assets[tokenId];
    }

    /// @notice Modifier to check if the caller is the owner of the token
    /// @param tokenId The ID of the asset token
    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        _;
    }

    /// @dev Override functions to support ERC721Enumerable and ERC721URIStorage
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
