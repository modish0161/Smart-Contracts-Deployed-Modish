// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract OperatorControlledRedemption is ERC777, Ownable, Pausable {

    // Mapping to track operators
    mapping(address => bool) private operators;

    event OperatorUpdated(address indexed operator, bool status);
    event TokensRedeemed(address indexed holder, uint256 amount, string assetType);

    constructor(string memory name, string memory symbol, address[] memory defaultOperators) 
        ERC777(name, symbol, defaultOperators) {}

    // Modifier to restrict access to operators
    modifier onlyOperator() {
        require(operators[msg.sender], "Not an operator");
        _;
    }

    // Function to set operators
    function setOperator(address operator, bool status) external onlyOwner {
        operators[operator] = status;
        emit OperatorUpdated(operator, status);
    }

    // Function to redeem tokens for underlying assets
    function redeemTokens(address holder, uint256 amount, string memory assetType) external onlyOperator whenNotPaused {
        require(balanceOf(holder) >= amount, "Insufficient balance");
        
        // Logic to manage redemption of underlying assets can be implemented here
        
        // Burn the tokens being redeemed
        _burn(holder, amount, "");
        
        emit TokensRedeemed(holder, amount, assetType);
    }

    // Function to pause token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override _beforeTokenTransfer to implement pausable functionality
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC777, Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
