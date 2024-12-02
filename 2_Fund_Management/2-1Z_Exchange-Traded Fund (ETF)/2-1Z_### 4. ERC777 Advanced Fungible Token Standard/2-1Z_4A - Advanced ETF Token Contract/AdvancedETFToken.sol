// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AdvancedETFToken is ERC777, Ownable, Pausable {

    // Mapping to track operators
    mapping(address => bool) private operators;

    event OperatorUpdated(address operator, bool status);

    constructor(string memory name, string memory symbol, address[] memory defaultOperators) 
        ERC777(name, symbol, defaultOperators) {
        // Initial minting can be done here if necessary
    }

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

    // Function for operators to transfer tokens on behalf of holders
    function operatorTransfer(address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) 
        external onlyOperator {
        _transfer(from, to, amount, userData, operatorData);
    }

    // Function for operators to send tokens on behalf of holders
    function operatorSend(address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) 
        external onlyOperator {
        _send(from, to, amount, userData, operatorData);
    }

    // Function to mint tokens, can only be called by the owner
    function mint(address account, uint256 amount, bytes memory userData) external onlyOwner whenNotPaused {
        _mint(account, amount, userData, "");
    }

    // Function to burn tokens, can only be called by the owner
    function burn(uint256 amount, bytes memory data) external onlyOwner whenNotPaused {
        _burn(msg.sender, amount, data);
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
