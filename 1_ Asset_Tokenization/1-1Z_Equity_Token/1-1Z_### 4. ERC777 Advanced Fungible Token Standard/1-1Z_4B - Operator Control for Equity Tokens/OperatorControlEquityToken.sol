// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Operator Control for Equity Tokens
/// @notice This contract issues equity tokens with enhanced functionality, allowing authorized operators (e.g., custodians or compliance officers) to execute transactions or corporate actions on behalf of equity token holders.
contract OperatorControlEquityToken is ERC777, AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event CorporateActionExecuted(address indexed operator, address indexed from, address indexed to, uint256 amount, string actionType);

    /// @notice Constructor to initialize the equity token with advanced operator control features
    /// @param name The name of the equity token
    /// @param symbol The symbol of the equity token
    /// @param defaultOperators The initial list of default operators
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Adds a new operator with the ability to execute actions on behalf of token holders
    /// @param operator The address of the operator to be added
    function addOperator(address operator) external onlyRole(ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, operator);
        emit OperatorAdded(operator);
    }

    /// @notice Removes an operator's ability to execute actions on behalf of token holders
    /// @param operator The address of the operator to be removed
    function removeOperator(address operator) external onlyRole(ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, operator);
        emit OperatorRemoved(operator);
    }

    /// @notice Allows an operator to transfer tokens on behalf of a shareholder, ensuring compliance
    /// @param from The address of the token holder
    /// @param to The address to transfer the tokens to
    /// @param amount The amount of tokens to transfer
    function operatorTransfer(address from, address to, uint256 amount) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        _move(msg.sender, from, to, amount, "", "", true);
        emit CorporateActionExecuted(msg.sender, from, to, amount, "Transfer");
    }

    /// @notice Allows an operator to execute a corporate action (e.g., dividend distribution, stock split)
    /// @param from The address of the token holder
    /// @param to The address to execute the action for
    /// @param amount The amount involved in the action
    /// @param actionType The type of corporate action (e.g., "Dividend", "StockSplit")
    function executeCorporateAction(address from, address to, uint256 amount, string calldata actionType) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(bytes(actionType).length > 0, "Invalid action type");
        _move(msg.sender, from, to, amount, "", "", true);
        emit CorporateActionExecuted(msg.sender, from, to, amount, actionType);
    }

    /// @notice Pauses all token transfers and operator actions
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses all token transfers and operator actions
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Emergency function to allow the admin to withdraw any ETH mistakenly sent to this contract
    function emergencyWithdrawETH() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(msg.sender).transfer(balance);
    }

    /// @notice Emergency function to allow the admin to withdraw any ERC20 tokens mistakenly sent to this contract
    /// @param token The address of the ERC20 token
    /// @param amount The amount of tokens to withdraw
    function emergencyWithdrawERC20(address token, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transfer(msg.sender, amount);
    }

    /// @notice Override required by Solidity for ERC777 _beforeTokenTransfer hook
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    /// @notice Fallback function to accept ETH deposits
    receive() external payable {}
}
