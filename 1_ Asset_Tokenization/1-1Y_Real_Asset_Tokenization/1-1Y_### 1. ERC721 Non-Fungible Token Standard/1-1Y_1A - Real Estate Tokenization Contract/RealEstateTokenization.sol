// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Real Estate Tokenization Contract
/// @notice This contract tokenizes individual real estate properties as ERC721 tokens, making each property tradable on the blockchain.
/// @dev Each ERC721 token represents a unique property, with compliance and upgrade capabilities.
contract RealEstateTokenization is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Counter for token IDs
    Counters.Counter private _tokenIdCounter;

    // Role for property verifiers
    bytes32 public constant PROPERTY_VERIFIER_ROLE = keccak256("PROPERTY_VERIFIER_ROLE");

    // Structure to hold property details
    struct Property {
        uint256 id;
        string location;
        uint256 area;
        uint256 value;
        bool isForSale;
    }

    // Mapping from token ID to Property details
    mapping(uint256 => Property) private _properties;

    // Events
    event PropertyTokenized(uint256 indexed tokenId, address indexed owner, string location, uint256 area, uint256 value);
    event PropertyForSale(uint256 indexed tokenId, uint256 value);
    event PropertySold(uint256 indexed tokenId, address indexed buyer, uint256 value);

    /// @dev Constructor to initialize the ERC721 contract with name and symbol
    constructor() ERC721("RealEstateToken", "RET") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PROPERTY_VERIFIER_ROLE, msg.sender);
    }

    /// @notice Function to tokenize a new property
    /// @param to Address of the token owner
    /// @param location The location of the property
    /// @param area The area of the property in square feet/meters
    /// @param value The value of the property in the desired currency
    /// @param uri Metadata URI for the property token
    /// @dev Only accounts with the PROPERTY_VERIFIER_ROLE can call this function
    function tokenizeProperty(
        address to,
        string memory location,
        uint256 area,
        uint256 value,
        string memory uri
    ) external onlyRole(PROPERTY_VERIFIER_ROLE) nonReentrant {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);

        _properties[tokenId] = Property(tokenId, location, area, value, false);
        emit PropertyTokenized(tokenId, to, location, area, value);
    }

    /// @notice Function to set a property for sale
    /// @param tokenId The ID of the property token
    /// @param saleValue The sale value of the property
    /// @dev Only the owner of the token can set it for sale
    function setPropertyForSale(uint256 tokenId, uint256 saleValue) external onlyOwnerOf(tokenId) {
        require(_properties[tokenId].isForSale == false, "Property is already for sale");
        _properties[tokenId].isForSale = true;
        _properties[tokenId].value = saleValue;

        emit PropertyForSale(tokenId, saleValue);
    }

    /// @notice Function to purchase a property that is for sale
    /// @param tokenId The ID of the property token to be purchased
    /// @dev The buyer must send the exact sale value to the contract
    function purchaseProperty(uint256 tokenId) external payable nonReentrant {
        Property memory property = _properties[tokenId];
        require(property.isForSale, "Property is not for sale");
        require(msg.value == property.value, "Incorrect value sent");

        address seller = ownerOf(tokenId);
        _properties[tokenId].isForSale = false;

        _transfer(seller, msg.sender, tokenId);
        payable(seller).transfer(msg.value);

        emit PropertySold(tokenId, msg.sender, msg.value);
    }

    /// @notice Function to get the details of a property
    /// @param tokenId The ID of the property token
    /// @return Property details including id, location, area, value, and sale status
    function getPropertyDetails(uint256 tokenId) external view returns (Property memory) {
        return _properties[tokenId];
    }

    /// @notice Modifier to check if the caller is the owner of the token
    /// @param tokenId The ID of the property token
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
