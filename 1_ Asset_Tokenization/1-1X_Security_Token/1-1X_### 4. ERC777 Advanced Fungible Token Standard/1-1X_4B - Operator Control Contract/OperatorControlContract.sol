// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Operator Control Contract
/// @notice ERC777 token with enhanced operator functionalities, allowing authorized operators to manage transactions on behalf of security token holders.
contract OperatorControlContract is ERC777, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Event emitted when an operator performs a controlled transaction
    event OperatorExecuted(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data);

    /// @notice Constructor to initialize the ERC777 token
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param defaultOperators_ List of default operators
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) ERC777(name_, symbol_, defaultOperators_) {
        // Grant the contract deployer the default admin and pauser roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice Function for an operator to perform a controlled transaction on behalf of a token holder
    /// @param from Address from which the tokens will be debited
    /// @param to Address to which the tokens will be credited
    /// @param amount Number of tokens to be transferred
    /// @param data Additional data to be logged
    function operatorExecute(address from, address to, uint256 amount, bytes memory data) public onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        require(from != address(0), "OperatorControlContract: from address cannot be zero");
        require(to != address(0), "OperatorControlContract: to address cannot be zero");
        require(amount > 0, "OperatorControlContract: amount must be greater than zero");
        
        _send(from, to, amount, data, "", true);
        emit OperatorExecuted(msg.sender, from, to, amount, data);
    }

    /// @notice Add a new operator with the OPERATOR_ROLE
    /// @param operator Address to be granted the operator role
    function addOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, operator);
    }

    /// @notice Remove an existing operator with the OPERATOR_ROLE
    /// @param operator Address to be revoked the operator role
    function removeOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, operator);
    }

    /// @notice Pause the contract, preventing all token transfers
    /// @dev Only accounts with the PAUSER_ROLE can pause the contract
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing token transfers
    /// @dev Only accounts with the PAUSER_ROLE can unpause the contract
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Override the _beforeTokenTransfer function to include pausability
    /// @dev Prevent token transfers when the contract is paused
    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    /// @notice Check if an address has the OPERATOR_ROLE
    /// @param operator Address to check for the operator role
    /// @return true if the address has the operator role, false otherwise
    function isOperator(address operator) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, operator);
    }
}
