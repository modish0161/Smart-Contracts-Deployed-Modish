// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract DividendDistribution is ERC20, Ownable, Pausable, ERC20Burnable {
    uint256 public totalDividends;
    mapping(address => uint256) public dividends;
    mapping(address => uint256) public lastClaimed;

    event DividendsDeposited(uint256 amount);
    event DividendsClaimed(address indexed user, uint256 amount);

    constructor() ERC20("Fungible ETF Token", "FET") {
        // Initial minting of tokens can be done here if necessary
    }

    // Function to deposit dividends into the contract
    function depositDividends() external payable onlyOwner {
        totalDividends += msg.value;
        emit DividendsDeposited(msg.value);
    }

    // Function to calculate dividends for an address
    function calculateDividends(address account) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) return 0;
        return (balanceOf(account) * totalDividends) / totalSupply;
    }

    // Function to claim dividends
    function claimDividends() external whenNotPaused {
        uint256 dividendsToClaim = calculateDividends(msg.sender) - lastClaimed[msg.sender];
        require(dividendsToClaim > 0, "No dividends available for claim");

        lastClaimed[msg.sender] += dividendsToClaim;
        payable(msg.sender).transfer(dividendsToClaim);
        emit DividendsClaimed(msg.sender, dividendsToClaim);
    }

    // Pause token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override transfer functions to incorporate pausable functionality
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
