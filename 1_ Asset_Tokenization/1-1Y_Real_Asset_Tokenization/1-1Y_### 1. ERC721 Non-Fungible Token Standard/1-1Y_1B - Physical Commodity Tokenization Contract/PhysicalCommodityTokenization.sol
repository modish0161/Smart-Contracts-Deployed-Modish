// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Physical Commodity Tokenization Contract
/// @notice This contract tokenizes physical commodities such as gold, oil, or precious metals, using the ERC721 standard.
/// @dev Each ERC721 token represents ownership of a specific, tangible commodity stored in a secure location.
contract PhysicalCommodityTokenization is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, AccessControl, ReentrancyGuard {
    using Strings for uint256;

    // Counter for token IDs
    uint256 private _tokenIdCounter;

    // Role for commodity verifiers
    bytes32 public constant COMMODITY_VERIFIER_ROLE = keccak256("COMMODITY_VERIFIER_ROLE");

    // Structure to hold commodity details
    struct Commodity {
        uint256 id;
        string name;
        string description;
        uint256 quantity;
        string unit;
        bool isForSale;
        uint256 price;
    }

    // Mapping from token ID to Commodity details
    mapping(uint256 => Commodity) private _commodities;

    // Events
    event CommodityTokenized(uint256 indexed tokenId, address indexed owner, string name, uint256 quantity, string unit, uint256 price);
    event CommodityForSale(uint256 indexed tokenId, uint256 price);
    event CommoditySold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    /// @dev Constructor to initialize the ERC721 contract with name and symbol
    constructor() ERC721("PhysicalCommodityToken", "PCT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMMODITY_VERIFIER_ROLE, msg.sender);
    }

    /// @notice Function to tokenize a new commodity
    /// @param to Address of the token owner
    /// @param name The name of the commodity
    /// @param description The description of the commodity
    /// @param quantity The quantity of the commodity
    /// @param unit The unit of the commodity (e.g., kg, barrels)
    /// @param price The value of the commodity in the desired currency
    /// @param uri Metadata URI for the commodity token
    /// @dev Only accounts with the COMMODITY_VERIFIER_ROLE can call this function
    function tokenizeCommodity(
        address to,
        string memory name,
        string memory description,
        uint256 quantity,
        string memory unit,
        uint256 price,
        string memory uri
    ) external onlyRole(COMMODITY_VERIFIER_ROLE) nonReentrant {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);

        _commodities[tokenId] = Commodity(tokenId, name, description, quantity, unit, false, price);
        emit CommodityTokenized(tokenId, to, name, quantity, unit, price);
    }

    /// @notice Function to set a commodity for sale
    /// @param tokenId The ID of the commodity token
    /// @param salePrice The sale price of the commodity
    /// @dev Only the owner of the token can set it for sale
    function setCommodityForSale(uint256 tokenId, uint256 salePrice) external onlyOwnerOf(tokenId) {
        require(_commodities[tokenId].isForSale == false, "Commodity is already for sale");
        _commodities[tokenId].isForSale = true;
        _commodities[tokenId].price = salePrice;

        emit CommodityForSale(tokenId, salePrice);
    }

    /// @notice Function to purchase a commodity that is for sale
    /// @param tokenId The ID of the commodity token to be purchased
    /// @dev The buyer must send the exact sale price to the contract
    function purchaseCommodity(uint256 tokenId) external payable nonReentrant {
        Commodity memory commodity = _commodities[tokenId];
        require(commodity.isForSale, "Commodity is not for sale");
        require(msg.value == commodity.price, "Incorrect value sent");

        address seller = ownerOf(tokenId);
        _commodities[tokenId].isForSale = false;

        _transfer(seller, msg.sender, tokenId);
        payable(seller).transfer(msg.value);

        emit CommoditySold(tokenId, msg.sender, msg.value);
    }

    /// @notice Function to get the details of a commodity
    /// @param tokenId The ID of the commodity token
    /// @return Commodity details including id, name, description, quantity, unit, price, and sale status
    function getCommodityDetails(uint256 tokenId) external view returns (Commodity memory) {
        return _commodities[tokenId];
    }

    /// @notice Modifier to check if the caller is the owner of the token
    /// @param tokenId The ID of the commodity token
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
