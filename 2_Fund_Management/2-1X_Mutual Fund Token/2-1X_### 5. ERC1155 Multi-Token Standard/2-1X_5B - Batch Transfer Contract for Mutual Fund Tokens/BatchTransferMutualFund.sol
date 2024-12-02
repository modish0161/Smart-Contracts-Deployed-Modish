// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BatchTransferMutualFund is ERC1155, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant FUND_MANAGER_ROLE = keccak256("FUND_MANAGER_ROLE");

    struct Asset {
        string name;
        uint256 totalSupply;
    }

    mapping(uint256 => Asset) public assets;
    uint256 public nextAssetId;

    event AssetCreated(uint256 indexed assetId, string name, uint256 totalSupply);
    event TokensMinted(uint256 indexed assetId, address indexed account, uint256 amount);
    event TokensBurned(uint256 indexed assetId, address indexed account, uint256 amount);

    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FUND_MANAGER_ROLE, msg.sender);
    }

    // Modifier to check if the caller is a fund manager
    modifier onlyFundManager() {
        require(hasRole(FUND_MANAGER_ROLE, msg.sender), "Caller is not a fund manager");
        _;
    }

    // Function to create a new asset type within the mutual fund
    function createAsset(string memory name, uint256 initialSupply) external onlyFundManager {
        uint256 assetId = nextAssetId;
        assets[assetId] = Asset(name, initialSupply);

        _mint(msg.sender, assetId, initialSupply, "");
        emit AssetCreated(assetId, name, initialSupply);

        nextAssetId += 1;
    }

    // Function to mint new tokens for an asset
    function mintTokens(uint256 assetId, uint256 amount) external onlyFundManager {
        require(bytes(assets[assetId].name).length > 0, "Asset does not exist");

        assets[assetId].totalSupply += amount;
        _mint(msg.sender, assetId, amount, "");
        emit TokensMinted(assetId, msg.sender, amount);
    }

    // Function to burn tokens of an asset
    function burnTokens(uint256 assetId, uint256 amount) external {
        require(balanceOf(msg.sender, assetId) >= amount, "Insufficient balance");

        assets[assetId].totalSupply -= amount;
        _burn(msg.sender, assetId, amount);
        emit TokensBurned(assetId, msg.sender, amount);
    }

    // Batch transfer function for multiple asset types
    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds,
        uint256[] calldata amounts
    ) external whenNotPaused nonReentrant {
        require(assetIds.length == amounts.length, "Mismatched array lengths");
        require(to != address(0), "Invalid recipient address");

        for (uint256 i = 0; i < assetIds.length; i++) {
            require(balanceOf(from, assetIds[i]) >= amounts[i], "Insufficient balance for asset");
        }

        _safeBatchTransferFrom(from, to, assetIds, amounts, "");

        for (uint256 i = 0; i < assetIds.length; i++) {
            emit TransferSingle(msg.sender, from, to, assetIds[i], amounts[i]);
        }
    }

    // Function to pause all token transfers
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    // Function to unpause all token transfers
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Function to set a new URI for metadata
    function setURI(string memory newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    // Override _beforeTokenTransfer to implement the Pausable functionality
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal whenNotPaused override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Emergency withdrawal function in case of unexpected events
    function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    // Receive Ether function to accept investments or dividends
    receive() external payable {}
}
