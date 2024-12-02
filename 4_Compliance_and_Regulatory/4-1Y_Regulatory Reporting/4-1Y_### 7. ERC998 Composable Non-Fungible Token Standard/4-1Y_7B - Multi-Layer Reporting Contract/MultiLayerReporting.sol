// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC998 is IERC721 {
    function childContractByIndex(uint256 tokenId, uint256 index) external view returns (address childContract);
    function childTokenByIndex(uint256 tokenId, uint256 index) external view returns (uint256 childTokenId);
    function totalChildContracts(uint256 tokenId) external view returns (uint256);
    function totalChildTokens(uint256 tokenId, address childContract) external view returns (uint256);
}

contract MultiLayerReporting is ERC721, Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // Mapping from token ID to child contracts and their tokens
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private _childTokens;

    // Regulatory authority address
    address public regulatoryAuthority;

    // Reporting threshold based on depth of composability
    uint256 public reportingThreshold;

    // Events for multi-layer reporting
    event MultiLayerTokenCreated(uint256 indexed tokenId, address indexed creator, uint256 timestamp);
    event ChildTokenAttached(uint256 indexed tokenId, address childContract, uint256 childTokenId, uint256 timestamp);
    event ChildTokenDetached(uint256 indexed tokenId, address childContract, uint256 childTokenId, uint256 timestamp);
    event ReportSubmitted(uint256 indexed tokenId, address indexed owner, uint256 timestamp, string details);

    constructor(
        string memory name,
        string memory symbol,
        address _regulatoryAuthority,
        uint256 _reportingThreshold
    ) ERC721(name, symbol) {
        require(_regulatoryAuthority != address(0), "Invalid authority address");
        regulatoryAuthority = _regulatoryAuthority;
        reportingThreshold = _reportingThreshold;
    }

    // Function to set reporting threshold
    function setReportingThreshold(uint256 _threshold) external onlyOwner {
        reportingThreshold = _threshold;
    }

    // Function to set the regulatory authority address
    function setRegulatoryAuthority(address _address) external onlyOwner {
        require(_address != address(0), "Invalid authority address");
        regulatoryAuthority = _address;
    }

    // Function to mint a new multi-layer token
    function mintMultiLayerToken(address to, uint256 tokenId) external whenNotPaused onlyOwner {
        _safeMint(to, tokenId);
        emit MultiLayerTokenCreated(tokenId, msg.sender, block.timestamp);
    }

    // Function to attach a child token to a multi-layer token
    function attachChildToken(
        uint256 tokenId,
        address childContract,
        uint256 childTokenId
    ) external whenNotPaused nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        IERC721(childContract).safeTransferFrom(msg.sender, address(this), childTokenId);
        _childTokens[tokenId][childContract].add(childTokenId);

        emit ChildTokenAttached(tokenId, childContract, childTokenId, block.timestamp);
        _checkForReporting(tokenId);
    }

    // Function to detach a child token from a multi-layer token
    function detachChildToken(
        uint256 tokenId,
        address childContract,
        uint256 childTokenId
    ) external whenNotPaused nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        require(_childTokens[tokenId][childContract].contains(childTokenId), "Child token not attached");

        _childTokens[tokenId][childContract].remove(childTokenId);
        IERC721(childContract).safeTransferFrom(address(this), msg.sender, childTokenId);

        emit ChildTokenDetached(tokenId, childContract, childTokenId, block.timestamp);
        _checkForReporting(tokenId);
    }

    // Internal function to check if reporting is required
    function _checkForReporting(uint256 tokenId) internal {
        uint256 totalComponents = _getTotalComponents(tokenId);
        if (totalComponents >= reportingThreshold) {
            _submitReport(tokenId);
        }
    }

    // Internal function to submit a report to the regulatory authority
    function _submitReport(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        string memory details = _getTokenDetails(tokenId);
        emit ReportSubmitted(tokenId, owner, block.timestamp, details);
    }

    // Function to get multi-layer token details for reporting
    function _getTokenDetails(uint256 tokenId) internal view returns (string memory) {
        string memory details = "";
        uint256 childContractCount = _getChildContractCount(tokenId);

        for (uint256 i = 0; i < childContractCount; i++) {
            address childContract = _getChildContractByIndex(tokenId, i);
            uint256 childTokenCount = _getChildTokenCount(tokenId, childContract);

            for (uint256 j = 0; j < childTokenCount; j++) {
                uint256 childTokenId = _getChildTokenByIndex(tokenId, childContract, j);
                details = string(abi.encodePacked(
                    details,
                    "ChildContract: ",
                    Strings.toHexString(uint256(uint160(childContract)), 20),
                    ", ChildTokenId: ",
                    Strings.toString(childTokenId),
                    "; "
                ));
            }
        }
        return details;
    }

    // Function to get the total number of components
    function _getTotalComponents(uint256 tokenId) internal view returns (uint256) {
        uint256 totalComponents = 0;
        uint256 childContractCount = _getChildContractCount(tokenId);

        for (uint256 i = 0; i < childContractCount; i++) {
            address childContract = _getChildContractByIndex(tokenId, i);
            totalComponents += _getChildTokenCount(tokenId, childContract);
        }
        return totalComponents;
    }

    // Function to get the count of child contracts
    function _getChildContractCount(uint256 tokenId) public view returns (uint256) {
        return _childTokens[tokenId][address(0)].length();
    }

    // Function to get a child contract by index
    function _getChildContractByIndex(uint256 tokenId, uint256 index) public view returns (address) {
        return address(uint160(_childTokens[tokenId][address(0)].at(index)));
    }

    // Function to get the count of child tokens for a specific contract
    function _getChildTokenCount(uint256 tokenId, address childContract) public view returns (uint256) {
        return _childTokens[tokenId][childContract].length();
    }

    // Function to get a child token by index for a specific contract
    function _getChildTokenByIndex(uint256 tokenId, address childContract, uint256 index) public view returns (uint256) {
        return _childTokens[tokenId][childContract].at(index);
    }

    // ERC721Receiver function to handle safe transfers
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
