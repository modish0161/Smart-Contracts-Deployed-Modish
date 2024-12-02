// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";
import "@openzeppelin/contracts/token/ERC998/extensions/ERC998TopDownEnumerable.sol";

contract ComposableAssetBundling is
    ERC998TopDown,
    ERC998TopDownEnumerable,
    ERC721Burnable,
    ERC721Pausable,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Struct to store bundle details
    struct BundleDetails {
        string name;
        string description;
        string uri;
        uint256 creationTime;
    }

    // Mapping from token ID to bundle details
    mapping(uint256 => BundleDetails) public bundleDetails;

    // Events
    event BundleCreated(uint256 indexed tokenId, string name, string uri);

    constructor() ERC721("Composable Asset Bundling", "CAB") {}

    /**
     * @dev Creates a new composable asset bundle.
     * @param _name Name of the asset bundle.
     * @param _description Description of the asset bundle.
     * @param _uri URI containing the metadata of the asset bundle.
     */
    function createBundle(
        string memory _name,
        string memory _description,
        string memory _uri
    ) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _uri);

        BundleDetails memory newBundleDetails = BundleDetails({
            name: _name,
            description: _description,
            uri: _uri,
            creationTime: block.timestamp
        });

        bundleDetails[newTokenId] = newBundleDetails;

        emit BundleCreated(newTokenId, _name, _uri);

        return newTokenId;
    }

    /**
     * @dev Adds a child token to the asset bundle.
     * @param _bundleId ID of the asset bundle.
     * @param _from Address of the child token holder.
     * @param _childContract Address of the child token contract.
     * @param _childTokenId Token ID of the child token.
     */
    function addChildToken(
        uint256 _bundleId,
        address _from,
        address _childContract,
        uint256 _childTokenId
    ) external nonReentrant whenNotPaused {
        require(ownerOf(_bundleId) == msg.sender, "Caller is not the owner of the bundle");
        _transferChild(_from, _bundleId, _childContract, _childTokenId);
    }

    /**
     * @dev Burns the asset bundle token and releases the underlying assets.
     * @param _bundleId ID of the asset bundle to burn.
     */
    function burnBundle(uint256 _bundleId) external nonReentrant whenNotPaused {
        require(ownerOf(_bundleId) == msg.sender, "Caller is not the owner of the bundle");
        _burn(_bundleId);
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override required functions from inherited contracts
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC998TopDown)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC998TopDown, ERC998TopDownEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
