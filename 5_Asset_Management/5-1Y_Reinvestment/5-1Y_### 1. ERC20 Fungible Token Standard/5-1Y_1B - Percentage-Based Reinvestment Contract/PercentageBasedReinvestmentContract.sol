// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PercentageBasedReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // ERC20 token for reinvestment and dividend distribution
    IERC20 public investmentToken;
    IERC20 public dividendToken;

    // Minimum reinvestment percentage (in basis points, where 100% = 10000)
    uint256 public minimumReinvestmentPercentage;

    // Mapping to store user reinvestment percentages
    mapping(address => uint256) public userReinvestmentPercentages;

    // Mapping to store user dividend balances
    mapping(address => uint256) public userDividendBalances;

    // Event declarations
    event DividendsDeposited(address indexed user, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 reinvestedAmount, uint256 withdrawnAmount);
    event ReinvestmentPercentageUpdated(address indexed user, uint256 oldPercentage, uint256 newPercentage);

    // Constructor to initialize the contract with ERC20 tokens and a default minimum reinvestment percentage
    constructor(address _investmentToken, address _dividendToken, uint256 _minimumReinvestmentPercentage) {
        require(_minimumReinvestmentPercentage <= 10000, "Percentage cannot exceed 100%");
        investmentToken = IERC20(_investmentToken);
        dividendToken = IERC20(_dividendToken);
        minimumReinvestmentPercentage = _minimumReinvestmentPercentage;
    }

    // Function to deposit dividends
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        dividendToken.transferFrom(msg.sender, address(this), amount);
        userDividendBalances[msg.sender] = userDividendBalances[msg.sender].add(amount);

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function to set user reinvestment percentage
    function setReinvestmentPercentage(uint256 percentage) external whenNotPaused {
        require(percentage >= minimumReinvestmentPercentage, "Percentage below minimum");
        require(percentage <= 10000, "Percentage cannot exceed 100%");
        
        uint256 oldPercentage = userReinvestmentPercentages[msg.sender];
        userReinvestmentPercentages[msg.sender] = percentage;

        emit ReinvestmentPercentageUpdated(msg.sender, oldPercentage, percentage);
    }

    // Function to reinvest profits and withdraw the remaining amount
    function reinvestProfits() external whenNotPaused nonReentrant {
        uint256 dividendBalance = userDividendBalances[msg.sender];
        require(dividendBalance > 0, "No dividends to reinvest");

        uint256 reinvestmentPercentage = userReinvestmentPercentages[msg.sender];
        uint256 reinvestedAmount = dividendBalance.mul(reinvestmentPercentage).div(10000);
        uint256 withdrawnAmount = dividendBalance.sub(reinvestedAmount);

        // Transfer reinvested tokens to user
        require(investmentToken.transfer(msg.sender, reinvestedAmount), "Investment token transfer failed");

        // Transfer withdrawn dividends to user
        require(dividendToken.transfer(msg.sender, withdrawnAmount), "Dividend token transfer failed");

        // Update user balance
        userDividendBalances[msg.sender] = 0;

        emit ProfitsReinvested(msg.sender, reinvestedAmount, withdrawnAmount);
    }

    // Function to update the minimum reinvestment percentage (admin only)
    function updateMinimumReinvestmentPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 10000, "Percentage cannot exceed 100%");
        minimumReinvestmentPercentage = newPercentage;
    }

    // Function to withdraw dividend tokens (admin only)
    function withdrawDividendTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.transfer(owner(), amount), "Withdrawal failed");
    }

    // Function to pause the contract (admin only)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (admin only)
    function unpause() external onlyOwner {
        _unpause();
    }
}
