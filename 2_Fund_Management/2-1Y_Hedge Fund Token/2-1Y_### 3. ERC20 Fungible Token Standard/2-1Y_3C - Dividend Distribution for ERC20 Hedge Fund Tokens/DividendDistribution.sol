// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DividendDistribution is ERC20, Ownable, ReentrancyGuard {
    mapping(address => uint256) public dividends; // Track dividends owed to each token holder
    mapping(address => uint256) public lastClaimed; // Track last claimed dividend for each address
    uint256 public totalDividends; // Total dividends available for distribution

    event DividendDistributed(uint256 amount);
    event DividendClaimed(address indexed holder, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Function to distribute dividends to all token holders
    function distributeDividends(uint256 amount) external onlyOwner {
        require(totalSupply() > 0, "No tokens minted");
        require(amount > 0, "Amount must be greater than 0");

        totalDividends += amount;
        emit DividendDistributed(amount);
    }

    // Function for token holders to claim their dividends
    function claimDividends() external nonReentrant {
        uint256 owed = calculateOwedDividends(msg.sender);
        require(owed > 0, "No dividends available to claim");

        dividends[msg.sender] = 0; // Reset owed dividends
        _mint(msg.sender, owed); // Mint new tokens as dividends
        lastClaimed[msg.sender] = totalDividends; // Update last claimed dividends

        emit DividendClaimed(msg.sender, owed);
    }

    // Calculate owed dividends for a holder
    function calculateOwedDividends(address holder) internal view returns (uint256) {
        uint256 newDividends = totalDividends - lastClaimed[holder];
        return (balanceOf(holder) * newDividends) / totalSupply(); // Proportional distribution
    }

    // Function to view dividends owed without claiming
    function viewOwedDividends(address holder) external view returns (uint256) {
        return calculateOwedDividends(holder);
    }
}
