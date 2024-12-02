// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ProfitSharingAndDividendDistribution is ERC777, Ownable, Pausable {
    
    // Mapping to track dividend balances
    mapping(address => uint256) private dividends;

    // Total profits for distribution
    uint256 private totalProfits;

    event DividendsDistributed(uint256 amount);
    event DividendsClaimed(address indexed holder, uint256 amount);

    constructor(string memory name, string memory symbol, address[] memory defaultOperators)
        ERC777(name, symbol, defaultOperators) {}

    // Function to distribute profits as dividends
    function distributeDividends(uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        totalProfits += amount;
        emit DividendsDistributed(amount);
    }

    // Function to calculate dividends for a specific holder
    function calculateDividends(address holder) internal view returns (uint256) {
        uint256 holderBalance = balanceOf(holder);
        return (holderBalance * totalProfits) / totalSupply();
    }

    // Function for holders to claim their dividends
    function claimDividends() external whenNotPaused {
        uint256 dividendsToClaim = calculateDividends(msg.sender);
        require(dividendsToClaim > 0, "No dividends to claim");

        dividends[msg.sender] += dividendsToClaim;
        totalProfits -= dividendsToClaim;

        // Transfer dividends as tokens
        _mint(msg.sender, dividendsToClaim, "", "");

        emit DividendsClaimed(msg.sender, dividendsToClaim);
    }

    // Function to view unclaimed dividends for a specific holder
    function viewUnclaimedDividends(address holder) external view returns (uint256) {
        return calculateDividends(holder);
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
