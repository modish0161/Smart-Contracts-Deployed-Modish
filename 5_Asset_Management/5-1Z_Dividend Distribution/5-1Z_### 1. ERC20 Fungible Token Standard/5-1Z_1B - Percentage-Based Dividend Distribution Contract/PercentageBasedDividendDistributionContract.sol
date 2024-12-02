// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PercentageBasedDividendDistributionContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public dividendToken; // ERC20 token used for dividend distribution
    mapping(address => uint256) public classPercentage; // Percentage allocation for each token class
    mapping(address => uint256) public totalDistributed; // Total dividends distributed per class

    event DividendsDeposited(address indexed from, uint256 amount);
    event DividendsAllocated(address indexed classToken, uint256 amount);
    event DividendWithdrawn(address indexed shareholder, address indexed classToken, uint256 amount);
    event ClassPercentageUpdated(address indexed classToken, uint256 percentage);

    constructor(address _dividendToken) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        dividendToken = IERC20(_dividendToken);
    }

    // Function to set the dividend percentage for each class of token
    function setClassPercentage(address classToken, uint256 percentage) external onlyOwner {
        require(classToken != address(0), "Invalid class token address");
        require(percentage > 0 && percentage <= 100, "Percentage must be between 1 and 100");
        classPercentage[classToken] = percentage;
        emit ClassPercentageUpdated(classToken, percentage);
    }

    // Function to deposit dividends into the contract for distribution
    function depositDividends(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        dividendToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit DividendsDeposited(msg.sender, _amount);
    }

    // Function to allocate dividends to each token class based on predefined percentages
    function allocateDividends(address[] calldata classTokens, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(address(this)) >= _amount, "Insufficient dividend balance");

        for (uint256 i = 0; i < classTokens.length; i++) {
            address classToken = classTokens[i];
            uint256 percentage = classPercentage[classToken];
            require(percentage > 0, "Class percentage not set");

            uint256 classDividend = _amount * percentage / 100;
            totalDistributed[classToken] += classDividend;

            emit DividendsAllocated(classToken, classDividend);
        }
    }

    // Function for shareholders to claim their dividends
    function claimDividends(address classToken) external nonReentrant {
        require(classPercentage[classToken] > 0, "Invalid class token or no dividends allocated");

        IERC20 classERC20 = IERC20(classToken);
        uint256 userBalance = classERC20.balanceOf(msg.sender);
        require(userBalance > 0, "No class tokens held");

        uint256 userShare = totalDistributed[classToken] * userBalance / classERC20.totalSupply();
        require(userShare > 0, "No dividends to claim");

        dividendToken.safeTransfer(msg.sender, userShare);
        totalDistributed[classToken] -= userShare;

        emit DividendWithdrawn(msg.sender, classToken, userShare);
    }

    // Function to view the total dividends distributed for a specific class token
    function getTotalDistributed(address classToken) external view returns (uint256) {
        return totalDistributed[classToken];
    }
}
