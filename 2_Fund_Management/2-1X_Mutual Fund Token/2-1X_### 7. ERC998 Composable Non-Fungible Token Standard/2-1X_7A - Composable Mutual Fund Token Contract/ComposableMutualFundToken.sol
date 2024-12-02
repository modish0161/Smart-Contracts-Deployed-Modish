// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";
import "@openzeppelin/contracts/token/ERC998/extensions/ERC998TopDownEnumerable.sol";

contract ComposableMutualFundToken is
    ERC998TopDown,
    ERC998TopDownEnumerable,
    ERC721Burnable,
    ERC721Pausable,
    Ownable,
    ReentrancyGuard
{
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // Struct to store the details of a fund
    struct FundDetails {
        string fundName;
        string fundDescription;
        string uri;
        uint256 creationTime;
    }

    // Mapping from token ID to fund details
    mapping(uint256 => FundDetails) public fundDetails;

    // Events
    event FundTokenCreated(uint256 indexed tokenId, string fundName, string uri);

    constructor() ERC721("Composable Mutual Fund Token", "CMFT") {}

    /**
     * @dev Creates a new composable mutual fund token.
     * @param _fundName Name of the mutual fund.
     * @param _fundDescription Description of the mutual fund.
     * @param _uri URI containing the metadata of the mutual fund.
     */
    function createFundToken(
        string memory _fundName,
        string memory _fundDescription,
        string memory _uri
    ) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _uri);

        FundDetails memory newFundDetails = FundDetails({
            fundName: _fundName,
            fundDescription: _fundDescription,
            uri: _uri,
            creationTime: block.timestamp
        });

        fundDetails[newTokenId] = newFundDetails;

        emit FundTokenCreated(newTokenId, _fundName, _uri);

        return newTokenId;
    }

    /**
     * @dev Allows adding child tokens to the mutual fund token.
     * @param _from Address of the child token holder.
     * @param _childContract Address of the child token contract.
     * @param _childTokenId Token ID of the child token.
     */
    function addChildToken(
        uint256 _tokenId,
        address _from,
        address _childContract,
        uint256 _childTokenId
    ) external nonReentrant whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the fund token");
        _transferChild(_from, _tokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Burns the mutual fund token and releases the underlying assets.
     * @param _tokenId Token ID of the mutual fund to burn.
     */
    function burnFundToken(uint256 _tokenId) external nonReentrant whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the fund token");
        _burn(_tokenId);
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
