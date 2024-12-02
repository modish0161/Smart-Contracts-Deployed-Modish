// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PerformanceFeeDistribution is ERC20, Ownable, ReentrancyGuard {
    uint256 public performanceFeePercentage; // Performance fee in basis points (1/100th of a percent)
    mapping(address => uint256) public profits; // Profits generated for each address
    mapping(address => uint256) public performanceFees; // Accumulated performance fees for each address

    event PerformanceFeeDistributed(address indexed manager, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 _performanceFeePercentage)
        ERC20(name, symbol) {
        performanceFeePercentage = _performanceFeePercentage;
    }

    modifier onlyManager() {
        require(msg.sender == owner(), "Only fund manager can call this function");
        _;
    }

    function recordProfit(address investor, uint256 profitAmount) external onlyManager {
        require(profitAmount > 0, "Profit amount must be greater than 0");
        profits[investor] += profitAmount;
    }

    function distributePerformanceFee(address manager) external onlyManager nonReentrant {
        uint256 totalProfits = profits[manager];
        require(totalProfits > 0, "No profits to distribute");

        uint256 feeAmount = (totalProfits * performanceFeePercentage) / 10000; // Calculate fee based on the performance fee percentage
        require(feeAmount > 0, "No performance fee to distribute");

        // Reset profits for the manager
        profits[manager] = 0;
        performanceFees[manager] += feeAmount;

        // Transfer the performance fee from the contract to the manager
        _mint(manager, feeAmount);
        emit PerformanceFeeDistributed(manager, feeAmount);
    }

    function withdrawPerformanceFees() external nonReentrant {
        uint256 feeAmount = performanceFees[msg.sender];
        require(feeAmount > 0, "No performance fees to withdraw");

        performanceFees[msg.sender] = 0; // Reset fee amount for the caller
        _mint(msg.sender, feeAmount); // Mint new tokens to the manager
    }
}
