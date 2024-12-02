// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Real Estate Tokenization Contract
/// @dev ERC721 contract to tokenize real estate properties as unique NFTs.
contract RealEstateTokenizationContract is ERC721, Ownable, AccessControl, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Role definitions for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Mapping to store metadata URI for each token
    mapping(uint256 => string) private _tokenURIs;

    /// @dev Event emitted when a new property token is minted
    event PropertyTokenMinted(address indexed owner, uint256 indexed tokenId, string tokenURI);

    /// @notice Constructor to initialize the contract with name and symbol
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // Grant the contract deployer the default admin, minter, and pauser roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice Mint a new property token
    /// @dev Only accounts with the MINTER_ROLE can mint new tokens
    /// @param to Address of the token owner
    /// @param tokenURI URI pointing to the property metadata
    /// @return tokenId The ID of the newly minted token
    function mintPropertyToken(address to, string memory tokenURI) public onlyRole(MINTER_ROLE) whenNotPaused returns (uint256) {
        require(to != address(0), "RealEstateTokenizationContract: mint to the zero address");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit PropertyTokenMinted(to, tokenId, tokenURI);
        return tokenId;
    }

    /// @notice Set the metadata URI for a specific token
    /// @param tokenId ID of the token
    /// @param tokenURI URI pointing to the property metadata
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        require(_exists(tokenId), "RealEstateTokenizationContract: URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenURI;
    }

    /// @notice Get the metadata URI of a specific token
    /// @param tokenId ID of the token
    /// @return The URI pointing to the property metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "RealEstateTokenizationContract: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /// @notice Pause the contract, preventing all token transfers and minting
    /// @dev Only accounts with the PAUSER_ROLE can pause the contract
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing token transfers and minting
    /// @dev Only accounts with the PAUSER_ROLE can unpause the contract
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Add a new minter with the MINTER_ROLE
    /// @param account Address to be granted the minter role
    function addMinter(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    /// @notice Remove an existing minter with the MINTER_ROLE
    /// @param account Address to be revoked the minter role
    function removeMinter(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }

    /// @notice Override _beforeTokenTransfer to include pausability
    /// @dev Prevent token transfers when the contract is paused
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Check if an address has the MINTER_ROLE
    /// @param account Address to check for the minter role
    /// @return true if the address has the minter role, false otherwise
    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    /// @notice Check if an address has the PAUSER_ROLE
    /// @param account Address to check for the pauser role
    /// @return true if the address has the pauser role, false otherwise
    function isPauser(address account) public view returns (bool) {
        return hasRole(PAUSER_ROLE, account);
    }
}
