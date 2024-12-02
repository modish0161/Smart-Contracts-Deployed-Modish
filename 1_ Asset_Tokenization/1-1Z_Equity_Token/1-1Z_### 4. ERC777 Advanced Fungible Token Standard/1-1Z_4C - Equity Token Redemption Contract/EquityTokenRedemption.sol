// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Equity Token Redemption Contract
/// @notice This contract allows shareholders to redeem their equity tokens for company assets or funds, providing liquidity and exit strategies for investors in tokenized equity offerings.
contract EquityTokenRedemption is ERC777, Ownable, ReentrancyGuard, Pausable {
    // Mapping to store the token redemption value in Ether for each token holder
    mapping(address => uint256) public redemptionValue;

    // Event emitted when tokens are redeemed
    event TokensRedeemed(address indexed redeemer, uint256 amount, uint256 value);

    /// @notice Constructor to initialize the ERC777 token and contract settings
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param defaultOperators The initial list of default operators
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function to set the redemption value for each token holder
    /// @param account The address of the token holder
    /// @param value The redemption value in Ether per token
    function setRedemptionValue(address account, uint256 value) external onlyOwner {
        redemptionValue[account] = value;
    }

    /// @notice Function to redeem tokens for Ether
    /// @param amount The amount of tokens to redeem
    function redeemTokens(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        uint256 redemptionAmount = redemptionValue[msg.sender] * amount;
        require(address(this).balance >= redemptionAmount, "Insufficient contract balance");

        _burn(msg.sender, amount, "", "");
        payable(msg.sender).transfer(redemptionAmount);

        emit TokensRedeemed(msg.sender, amount, redemptionAmount);
    }

    /// @notice Function to withdraw Ether from the contract (for owner)
    /// @param amount The amount of Ether to withdraw
    function withdrawEther(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner()).transfer(amount);
    }

    /// @notice Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Fallback function to receive Ether
    receive() external payable {}

    /// @notice Override required by Solidity for ERC777 _beforeTokenTransfer hook
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}
