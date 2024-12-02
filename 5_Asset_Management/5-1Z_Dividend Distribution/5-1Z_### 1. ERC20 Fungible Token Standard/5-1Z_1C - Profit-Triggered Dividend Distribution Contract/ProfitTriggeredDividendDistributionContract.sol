// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ProfitTriggeredDividendDistributionContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public dividendToken; // ERC20 token used for dividend distribution
    uint256 public profitThreshold; // Minimum profit required to trigger dividend distribution
    uint256 public totalProfits; // Accumulated profits in the contract

    event ProfitsDeposited(address indexed from, uint256 amount);
    event DividendsDistributed(uint256 amount);
    event DividendWithdrawn(address indexed shareholder, uint256 amount);
    event ProfitThresholdUpdated(uint256 newThreshold);

    constructor(address _dividendToken, uint256 _profitThreshold) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_profitThreshold > 0, "Profit threshold must be greater than zero");
        dividendToken = IERC20(_dividendToken);
        profitThreshold = _profitThreshold;
    }

    // Function to deposit profits into the contract
    function depositProfits(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        dividendToken.safeTransferFrom(msg.sender, address(this), _amount);
        totalProfits += _amount;

        emit ProfitsDeposited(msg.sender, _amount);

        // Automatically distribute dividends if profits exceed the threshold
        if (totalProfits >= profitThreshold) {
            _distributeDividends();
        }
    }

    // Internal function to distribute dividends to all token holders
    function _distributeDividends() internal {
        uint256 dividendAmount = totalProfits;
        totalProfits = 0; // Reset total profits after distribution

        // Distribute dividends proportionally to all token holders
        uint256 totalSupply = dividendToken.totalSupply();
        for (uint256 i = 0; i < totalSupply; i++) {
            address shareholder = address(uint160(i)); // Placeholder logic for shareholder retrieval
            uint256 shareholderBalance = dividendToken.balanceOf(shareholder);

            if (shareholderBalance > 0) {
                uint256 share = (dividendAmount * shareholderBalance) / totalSupply;
                dividendToken.safeTransfer(shareholder, share);

                emit DividendWithdrawn(shareholder, share);
            }
        }

        emit DividendsDistributed(dividendAmount);
    }

    // Function to set a new profit threshold
    function setProfitThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Profit threshold must be greater than zero");
        profitThreshold = _newThreshold;
        emit ProfitThresholdUpdated(_newThreshold);
    }

    // Function to manually trigger dividend distribution
    function triggerDividendDistribution() external onlyOwner nonReentrant {
        require(totalProfits >= profitThreshold, "Profits have not reached the threshold");
        _distributeDividends();
    }

    // Function to view total profits in the contract
    function getTotalProfits() external view returns (uint256) {
        return totalProfits;
    }
}
