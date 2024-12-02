// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BatchTransferETFToken is ERC1155, Ownable, Pausable {
    
    // Mapping to track total supply of each token ID
    mapping(uint256 => uint256) private _totalSupply;

    event AssetCreated(uint256 indexed id, uint256 supply);
    event AssetMinted(address indexed account, uint256 indexed id, uint256 amount);
    event AssetBurned(address indexed account, uint256 indexed id, uint256 amount);
    
    constructor(string memory uri) ERC1155(uri) {}

    // Function to create a new asset type
    function createAsset(uint256 id, uint256 initialSupply) external onlyOwner {
        require(_totalSupply[id] == 0, "Asset already exists");
        _totalSupply[id] = initialSupply;
        _mint(msg.sender, id, initialSupply, "");
        emit AssetCreated(id, initialSupply);
    }

    // Function to mint new tokens for a specific asset type
    function mint(uint256 id, uint256 amount, bytes memory data) external onlyOwner whenNotPaused {
        require(_totalSupply[id] + amount >= _totalSupply[id], "Minting exceeds total supply limit");
        _totalSupply[id] += amount;
        _mint(msg.sender, id, amount, data);
        emit AssetMinted(msg.sender, id, amount);
    }

    // Function to burn tokens of a specific asset type
    function burn(uint256 id, uint256 amount) external whenNotPaused {
        require(balanceOf(msg.sender, id) >= amount, "Insufficient balance to burn");
        _burn(msg.sender, id, amount);
        _totalSupply[id] -= amount;
        emit AssetBurned(msg.sender, id, amount);
    }

    // Function for batch transfer of tokens
    function batchTransfer(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external whenNotPaused {
        require(ids.length == amounts.length, "IDs and amounts length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            require(balanceOf(msg.sender, ids[i]) >= amounts[i], "Insufficient balance for transfer");
        }
        _safeBatchTransferFrom(msg.sender, to, ids, amounts, data);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to get total supply of an asset
    function totalSupply(uint256 id) external view returns (uint256) {
        return _totalSupply[id];
    }

    // Override _beforeTokenTransfer to implement pausable functionality
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
