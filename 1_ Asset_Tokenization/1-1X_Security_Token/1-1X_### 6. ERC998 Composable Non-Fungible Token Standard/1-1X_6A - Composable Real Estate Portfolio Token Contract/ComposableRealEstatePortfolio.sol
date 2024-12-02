// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Composable Real Estate Portfolio Token Contract
/// @dev ERC998 composable NFT contract for managing portfolios of real estate assets, each represented as ERC721 tokens.
contract ComposableRealEstatePortfolio is ERC721Enumerable, Ownable, AccessControl, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _portfolioIds;

    // Role definitions for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Mapping from portfolio ID to owned ERC721 tokens and their counts
    mapping(uint256 => mapping(address => uint256[])) private _ownedERC721Tokens;

    /// @dev Event emitted when a new portfolio token is minted
    event PortfolioTokenMinted(address indexed owner, uint256 indexed portfolioId);

    /// @dev Event emitted when an ERC721 token is added to a portfolio
    event ERC721TokenAdded(uint256 indexed portfolioId, address indexed erc721Address, uint256 indexed tokenId);

    /// @dev Event emitted when an ERC721 token is removed from a portfolio
    event ERC721TokenRemoved(uint256 indexed portfolioId, address indexed erc721Address, uint256 indexed tokenId);

    /// @notice Constructor to initialize the contract with name and symbol
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // Grant the contract deployer the default admin, minter, and pauser roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice Mint a new portfolio token
    /// @dev Only accounts with the MINTER_ROLE can mint new tokens
    /// @param to Address of the token owner
    /// @return portfolioId The ID of the newly minted portfolio token
    function mintPortfolioToken(address to) public onlyRole(MINTER_ROLE) whenNotPaused returns (uint256) {
        require(to != address(0), "ComposableRealEstatePortfolio: mint to the zero address");

        _portfolioIds.increment();
        uint256 portfolioId = _portfolioIds.current();

        _mint(to, portfolioId);
        emit PortfolioTokenMinted(to, portfolioId);

        return portfolioId;
    }

    /// @notice Add an ERC721 token to a portfolio
    /// @dev The sender must be the owner of both the portfolio token and the ERC721 token
    /// @param portfolioId ID of the portfolio token
    /// @param erc721Address Address of the ERC721 token contract
    /// @param tokenId ID of the ERC721 token to add
    function addERC721ToPortfolio(uint256 portfolioId, address erc721Address, uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, portfolioId), "ComposableRealEstatePortfolio: caller is not owner nor approved for portfolio");
        require(IERC721(erc721Address).ownerOf(tokenId) == msg.sender, "ComposableRealEstatePortfolio: caller is not owner of ERC721 token");

        IERC721(erc721Address).transferFrom(msg.sender, address(this), tokenId);
        _ownedERC721Tokens[portfolioId][erc721Address].push(tokenId);

        emit ERC721TokenAdded(portfolioId, erc721Address, tokenId);
    }

    /// @notice Remove an ERC721 token from a portfolio
    /// @dev The sender must be the owner of the portfolio token
    /// @param portfolioId ID of the portfolio token
    /// @param erc721Address Address of the ERC721 token contract
    /// @param tokenId ID of the ERC721 token to remove
    function removeERC721FromPortfolio(uint256 portfolioId, address erc721Address, uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, portfolioId), "ComposableRealEstatePortfolio: caller is not owner nor approved for portfolio");

        uint256[] storage tokenIds = _ownedERC721Tokens[portfolioId][erc721Address];
        bool found = false;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                found = true;
                break;
            }
        }
        require(found, "ComposableRealEstatePortfolio: ERC721 token not found in portfolio");

        IERC721(erc721Address).transferFrom(address(this), msg.sender, tokenId);
        emit ERC721TokenRemoved(portfolioId, erc721Address, tokenId);
    }

    /// @notice Get all ERC721 tokens owned by a portfolio
    /// @param portfolioId ID of the portfolio token
    /// @param erc721Address Address of the ERC721 token contract
    /// @return Array of ERC721 token IDs owned by the portfolio
    function getERC721TokensInPortfolio(uint256 portfolioId, address erc721Address) public view returns (uint256[] memory) {
        return _ownedERC721Tokens[portfolioId][erc721Address];
    }

    /// @notice Pause the contract, preventing all token transfers and portfolio modifications
    /// @dev Only accounts with the PAUSER_ROLE can pause the contract
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing token transfers and portfolio modifications
    /// @dev Only accounts with the PAUSER_ROLE can unpause the contract
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
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
}
