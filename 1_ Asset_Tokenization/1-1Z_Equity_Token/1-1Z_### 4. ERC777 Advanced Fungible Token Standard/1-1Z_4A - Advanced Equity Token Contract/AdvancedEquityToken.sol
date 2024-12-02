// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Advanced Equity Token Contract
/// @notice This contract issues equity tokens with enhanced functionality, allowing for features like authorized operators who can manage tokens on behalf of shareholders. This is useful in highly regulated industries or for larger enterprises.
contract AdvancedEquityToken is ERC777, Ownable, Pausable, ReentrancyGuard {
    // Mapping to track operators and their permissions
    mapping(address => bool) private _authorizedOperators;

    // Events
    event OperatorAuthorized(address indexed operator);
    event OperatorRevoked(address indexed operator);
    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed from, uint256 amount);

    /// @notice Constructor to initialize the equity token
    /// @param name The name of the equity token
    /// @param symbol The symbol of the equity token
    /// @param defaultOperators The initial list of default operators
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {}

    /// @notice Authorizes an operator to manage tokens on behalf of shareholders
    /// @param operator The address of the operator to be authorized
    function authorizeOperator(address operator) external onlyOwner {
        require(!_authorizedOperators[operator], "Operator already authorized");
        _authorizedOperators[operator] = true;
        emit OperatorAuthorized(operator);
    }

    /// @notice Revokes an operator's authorization
    /// @param operator The address of the operator to be revoked
    function revokeOperator(address operator) external onlyOwner {
        require(_authorizedOperators[operator], "Operator not authorized");
        _authorizedOperators[operator] = false;
        emit OperatorRevoked(operator);
    }

    /// @notice Checks if an address is an authorized operator
    /// @param operator The address to check
    /// @return bool indicating whether the address is an authorized operator
    function isAuthorizedOperator(address operator) public view returns (bool) {
        return _authorizedOperators[operator];
    }

    /// @notice Mints new equity tokens to a specified address
    /// @param to The address to receive the newly minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _mint(to, amount, "", "");
        emit TokenMinted(to, amount);
    }

    /// @notice Burns equity tokens from a specified address
    /// @param from The address from which to burn the tokens
    /// @param amount The amount of tokens to burn
    function burn(address from, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _burn(from, amount, "", "");
        emit TokenBurned(from, amount);
    }

    /// @notice Pauses all token transfers and operator actions
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses all token transfers and operator actions
    function unpause() external onlyOwner {
        _unpause();
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

    /// @notice Allows the owner to withdraw any ETH mistakenly sent to this contract
    function emergencyWithdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens mistakenly sent to this contract
    /// @param token The address of the ERC20 token
    /// @param amount The amount of tokens to withdraw
    function emergencyWithdrawERC20(address token, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transfer(owner(), amount);
    }

    /// @notice Fallback function to accept ETH deposits
    receive() external payable {}
}
