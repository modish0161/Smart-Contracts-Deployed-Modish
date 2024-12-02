// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Dividend Distribution for ERC20 Equity Tokens
/// @notice This contract automates the distribution of dividends to ERC20 equity token holders, providing them with their proportional share of profits.
contract DividendDistributionERC20 is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    mapping(address => uint256) public dividendBalanceOf;  // Tracks the dividend balance of each token holder
    mapping(address => uint256) public lastDividendPoints; // Tracks the last dividend points of each holder
    uint256 public totalDividends; // Total dividends available for distribution
    uint256 public totalDividendPoints; // Total dividend points accumulated
    uint256 public pointMultiplier = 10 ** 18; // Multiplier to maintain accuracy in dividend calculations

    event DividendsDistributed(address indexed from, uint256 amount);
    event DividendClaimed(address indexed to, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @notice Distributes dividends to all token holders
    /// @dev Dividends are distributed proportionally based on the number of tokens held
    /// @param amount The total amount of dividends to distribute
    function distributeDividends(uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Dividend amount must be greater than zero");
        require(totalSupply() > 0, "No tokens exist");

        totalDividends = totalDividends.add(amount);
        totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(totalSupply()));

        emit DividendsDistributed(msg.sender, amount);
    }

    /// @notice Calculates the dividends owed to a token holder
    /// @param account The address of the token holder
    function dividendsOwing(address account) public view returns(uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(lastDividendPoints[account]);
        return balanceOf(account).mul(newDividendPoints).div(pointMultiplier);
    }

    /// @notice Allows token holders to claim their dividends
    function claimDividends() external nonReentrant whenNotPaused {
        updateAccount(msg.sender);
        uint256 owing = dividendBalanceOf[msg.sender];
        require(owing > 0, "No dividends available for withdrawal");

        dividendBalanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(owing);
        
        emit DividendClaimed(msg.sender, owing);
    }

    /// @notice Updates the dividend balance and last dividend points for a token holder
    /// @param account The address of the token holder
    function updateAccount(address account) internal {
        uint256 owing = dividendsOwing(account);
        if (owing > 0) {
            dividendBalanceOf[account] = dividendBalanceOf[account].add(owing);
        }
        lastDividendPoints[account] = totalDividendPoints;
    }

    /// @notice Overrides the _transfer function to update dividends before transferring tokens
    /// @param from The address from which tokens are being transferred
    /// @param to The address to which tokens are being transferred
    /// @param amount The amount of tokens being transferred
    function _transfer(address from, address to, uint256 amount) internal override {
        updateAccount(from);
        updateAccount(to);
        super._transfer(from, to, amount);
    }

    /// @notice Function to handle emergency withdrawals of dividends
    /// @param amount Amount of dividends to withdraw
    function emergencyWithdraw(uint256 amount) external onlyOwner nonReentrant whenPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        payable(owner()).transfer(amount);
    }

    /// @notice Pauses the contract, disabling dividend distribution and claiming
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, enabling dividend distribution and claiming
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Fallback function to accept ETH deposits
    receive() external payable {}
}
