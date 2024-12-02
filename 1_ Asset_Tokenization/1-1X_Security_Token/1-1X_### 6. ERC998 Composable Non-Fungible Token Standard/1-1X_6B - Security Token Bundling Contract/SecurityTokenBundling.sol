// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Security Token Bundling Contract
/// @dev ERC998 composable NFT contract for managing bundles of security tokens or NFTs.
contract SecurityTokenBundling is ERC721Enumerable, Ownable, AccessControl, ReentrancyGuard {
    using Strings for uint256;

    // Role definitions for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Mapping from bundle ID to owned ERC721 tokens and their counts
    mapping(uint256 => mapping(address => uint256[])) private _ownedERC721Tokens;

    /// @dev Event emitted when a new bundle token is minted
    event BundleTokenMinted(address indexed owner, uint256 indexed bundleId);

    /// @dev Event emitted when an ERC721 token is added to a bundle
    event ERC721TokenAdded(uint256 indexed bundleId, address indexed erc721Address, uint256 indexed tokenId);

    /// @dev Event emitted when an ERC721 token is removed from a bundle
    event ERC721TokenRemoved(uint256 indexed bundleId, address indexed erc721Address, uint256 indexed tokenId);

    /// @notice Constructor to initialize the contract with name and symbol
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // Grant the contract deployer the default admin, minter, and operator roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    /// @notice Mint a new bundle token
    /// @dev Only accounts with the MINTER_ROLE can mint new tokens
    /// @param to Address of the token owner
    /// @return bundleId The ID of the newly minted bundle token
    function mintBundleToken(address to) public onlyRole(MINTER_ROLE) returns (uint256) {
        require(to != address(0), "SecurityTokenBundling: mint to the zero address");

        uint256 bundleId = totalSupply() + 1;

        _mint(to, bundleId);
        emit BundleTokenMinted(to, bundleId);

        return bundleId;
    }

    /// @notice Add an ERC721 token to a bundle
    /// @dev The sender must be the owner of both the bundle token and the ERC721 token
    /// @param bundleId ID of the bundle token
    /// @param erc721Address Address of the ERC721 token contract
    /// @param tokenId ID of the ERC721 token to add
    function addERC721ToBundle(uint256 bundleId, address erc721Address, uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, bundleId), "SecurityTokenBundling: caller is not owner nor approved for bundle");
        require(IERC721(erc721Address).ownerOf(tokenId) == msg.sender, "SecurityTokenBundling: caller is not owner of ERC721 token");

        IERC721(erc721Address).transferFrom(msg.sender, address(this), tokenId);
        _ownedERC721Tokens[bundleId][erc721Address].push(tokenId);

        emit ERC721TokenAdded(bundleId, erc721Address, tokenId);
    }

    /// @notice Remove an ERC721 token from a bundle
    /// @dev The sender must be the owner of the bundle token
    /// @param bundleId ID of the bundle token
    /// @param erc721Address Address of the ERC721 token contract
    /// @param tokenId ID of the ERC721 token to remove
    function removeERC721FromBundle(uint256 bundleId, address erc721Address, uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, bundleId), "SecurityTokenBundling: caller is not owner nor approved for bundle");

        uint256[] storage tokenIds = _ownedERC721Tokens[bundleId][erc721Address];
        bool found = false;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                found = true;
                break;
            }
        }
        require(found, "SecurityTokenBundling: ERC721 token not found in bundle");

        IERC721(erc721Address).transferFrom(address(this), msg.sender, tokenId);
        emit ERC721TokenRemoved(bundleId, erc721Address, tokenId);
    }

    /// @notice Get all ERC721 tokens owned by a bundle
    /// @param bundleId ID of the bundle token
    /// @param erc721Address Address of the ERC721 token contract
    /// @return Array of ERC721 token IDs owned by the bundle
    function getERC721TokensInBundle(uint256 bundleId, address erc721Address) public view returns (uint256[] memory) {
        return _ownedERC721Tokens[bundleId][erc721Address];
    }

    /// @notice Check if an address has the MINTER_ROLE
    /// @param account Address to check for the minter role
    /// @return true if the address has the minter role, false otherwise
    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    /// @notice Check if an address has the OPERATOR_ROLE
    /// @param account Address to check for the operator role
    /// @return true if the address has the operator role, false otherwise
    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
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

    /// @notice Add a new operator with the OPERATOR_ROLE
    /// @param account Address to be granted the operator role
    function addOperator(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, account);
    }

    /// @notice Remove an existing operator with the OPERATOR_ROLE
    /// @param account Address to be revoked the operator role
    function removeOperator(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, account);
    }

    /// @notice Override _beforeTokenTransfer to include only allowed transfers
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
