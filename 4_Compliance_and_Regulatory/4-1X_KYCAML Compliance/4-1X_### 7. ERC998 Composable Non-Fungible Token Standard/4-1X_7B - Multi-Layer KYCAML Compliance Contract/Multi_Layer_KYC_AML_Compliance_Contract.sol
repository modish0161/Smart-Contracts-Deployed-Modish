// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC998/IERC998.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDownEnumerable.sol";

contract MultiLayerKYCAMLCompliance is ERC998TopDown, ERC998TopDownEnumerable, Ownable, AccessControl, Pausable {
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    struct UserCompliance {
        bool isCompliant;
        uint256 verificationTimestamp;
    }

    struct AssetCompliance {
        bool isCompliant;
        uint256 verificationTimestamp;
    }

    mapping(address => UserCompliance) public userCompliance;
    mapping(uint256 => mapping(address => AssetCompliance)) public assetCompliance; // Mapping of tokenId to asset contracts to compliance

    event UserComplianceStatusUpdated(address indexed user, bool isCompliant, uint256 timestamp);
    event AssetComplianceStatusUpdated(uint256 indexed tokenId, address indexed asset, bool isCompliant, uint256 timestamp);

    constructor(string memory name_, string memory symbol_) ERC998TopDown(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
    }

    modifier onlyCompliant(address owner, uint256 tokenId) {
        require(userCompliance[owner].isCompliant, "User not compliant");
        require(isAssetCompliant(tokenId), "Asset not compliant");
        _;
    }

    function setUserComplianceStatus(address owner, bool status) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        userCompliance[owner] = UserCompliance(status, block.timestamp);
        emit UserComplianceStatusUpdated(owner, status, block.timestamp);
    }

    function setAssetComplianceStatus(uint256 tokenId, address assetContract, bool status) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        assetCompliance[tokenId][assetContract] = AssetCompliance(status, block.timestamp);
        emit AssetComplianceStatusUpdated(tokenId, assetContract, status, block.timestamp);
    }

    function isAssetCompliant(uint256 tokenId) public view returns (bool) {
        (uint256 childContractCount, ) = getChildContracts(tokenId);
        for (uint256 i = 0; i < childContractCount; i++) {
            address childContract = getChildContract(tokenId, i);
            if (!assetCompliance[tokenId][childContract].isCompliant) {
                return false;
            }
        }
        return true;
    }

    function mintComposableToken(address to, uint256 tokenId) external onlyRole(COMPLIANCE_OFFICER_ROLE) onlyCompliant(to, tokenId) {
        _safeMint(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyCompliant(to, tokenId) {
        require(userCompliance[from].isCompliant, "Sender not compliant");
        super.safeTransferFrom(from, to, tokenId);
    }

    function transferChild(
        uint256 fromTokenId,
        address to,
        uint256 childTokenId,
        IERC721 childContract
    ) external override onlyCompliant(to, fromTokenId) {
        require(userCompliance[msg.sender].isCompliant, "Caller not compliant");
        super.transferChild(fromTokenId, to, childTokenId, childContract);
    }

    function transferChildFromParent(
        uint256 fromTokenId,
        address to,
        uint256 childTokenId,
        IERC721 childContract
    ) external override onlyCompliant(to, fromTokenId) {
        require(userCompliance[msg.sender].isCompliant, "Caller not compliant");
        super.transferChildFromParent(fromTokenId, to, childTokenId, childContract);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Additional functionality for ERC998 top-down composable NFT standard
    function ownerOfChild(address childContract, uint256 childTokenId) public view override returns (bytes32, address) {
        return super.ownerOfChild(childContract, childTokenId);
    }

    function childExists(address childContract, uint256 childTokenId) public view returns (bool) {
        return super.childExists(childContract, childTokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC998TopDown, ERC998TopDownEnumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC998TopDown, ERC998TopDownEnumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
