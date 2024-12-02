// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/// @title Corporate Action Contract for ERC1400 Security Tokens
/// @notice This contract handles corporate actions such as stock splits, dividends, and buybacks on tokenized equity shares.
contract CorporateActionContract is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    IERC1400 public equityToken;

    // Events for corporate actions
    event DividendDistributed(uint256 amount, uint256 timestamp);
    event StockSplitExecuted(uint256 factor, uint256 timestamp);
    event BuybackExecuted(address indexed from, uint256 amount, uint256 timestamp);

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC1400 token representing the equity
    constructor(address _equityToken) {
        require(_equityToken != address(0), "CorporateActionContract: Invalid equity token address");

        equityToken = IERC1400(_equityToken);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    /// @notice Distributes dividends to all token holders
    /// @param amount Total dividend amount to be distributed
    function distributeDividends(uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(amount > 0, "CorporateActionContract: Dividend amount must be greater than zero");
        uint256 totalSupply = equityToken.totalSupply();
        require(totalSupply > 0, "CorporateActionContract: No tokens in circulation");

        // Calculate dividend per share
        uint256 dividendPerShare = amount / totalSupply;

        // Distribute dividends to all holders
        for (uint256 i = 0; i < totalSupply; i++) {
            address shareholder = equityToken.holderAt(i);
            uint256 balance = equityToken.balanceOf(shareholder);
            uint256 dividend = dividendPerShare * balance;
            (bool success, ) = shareholder.call{value: dividend}("");
            require(success, "CorporateActionContract: Dividend transfer failed");
        }

        emit DividendDistributed(amount, block.timestamp);
    }

    /// @notice Executes a stock split for the token
    /// @param splitFactor The factor by which the stock will be split
    function executeStockSplit(uint256 splitFactor) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(splitFactor > 1, "CorporateActionContract: Split factor must be greater than 1");

        uint256 totalSupply = equityToken.totalSupply();
        uint256 newTotalSupply = totalSupply * splitFactor;

        for (uint256 i = 0; i < totalSupply; i++) {
            address shareholder = equityToken.holderAt(i);
            uint256 balance = equityToken.balanceOf(shareholder);
            equityToken.mint(shareholder, balance * (splitFactor - 1));
        }

        emit StockSplitExecuted(splitFactor, block.timestamp);
    }

    /// @notice Executes a token buyback
    /// @param from Address from which tokens are being bought back
    /// @param amount Number of tokens to buy back
    function executeBuyback(address from, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(from != address(0), "CorporateActionContract: Invalid address");
        require(amount > 0, "CorporateActionContract: Amount must be greater than zero");
        require(equityToken.balanceOf(from) >= amount, "CorporateActionContract: Insufficient balance");

        equityToken.burn(from, amount);

        emit BuybackExecuted(from, amount, block.timestamp);
    }

    /// @notice Pauses the contract (only by admin)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract (only by admin)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Fallback function to receive dividends
    receive() external payable {}

    /// @notice Withdraws any remaining funds to the admin
    function withdrawFunds() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "CorporateActionContract: No funds to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "CorporateActionContract: Withdrawal failed");
    }
}
