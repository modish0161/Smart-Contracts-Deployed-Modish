// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MintingBurningHedgeFund is ERC20, Ownable, ReentrancyGuard {
    mapping(address => uint256) public contributions; // Track contributions of each investor
    uint256 public totalCapital; // Total capital managed by the hedge fund

    event TokensMinted(address indexed investor, uint256 amount);
    event TokensBurned(address indexed investor, uint256 amount);
    event CapitalIncreased(uint256 amount);
    event CapitalDecreased(uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Function to increase capital and mint tokens
    function increaseCapital(uint256 amount) external onlyOwner {
        totalCapital += amount;
        _mint(msg.sender, amount); // Mint tokens to the owner (or a specific address)
        emit CapitalIncreased(amount);
    }

    // Function for investors to contribute and receive tokens
    function contribute(uint256 amount) external nonReentrant {
        require(amount > 0, "Contribution must be greater than 0");

        contributions[msg.sender] += amount;
        _mint(msg.sender, amount); // Mint new tokens proportional to contribution
        emit TokensMinted(msg.sender, amount);
    }

    // Function for investors to withdraw and burn tokens
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        contributions[msg.sender] -= amount; // Deduct contribution
        _burn(msg.sender, amount); // Burn tokens on withdrawal
        emit TokensBurned(msg.sender, amount);
    }

    // Function to view total capital
    function getTotalCapital() external view returns (uint256) {
        return totalCapital;
    }
}
