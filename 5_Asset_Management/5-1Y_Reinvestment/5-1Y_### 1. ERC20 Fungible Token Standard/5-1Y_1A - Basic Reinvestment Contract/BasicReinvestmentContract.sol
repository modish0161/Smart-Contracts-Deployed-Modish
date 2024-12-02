// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BasicReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // Mapping to store user balances
    mapping(address => uint256) public userBalances;

    // ERC20 token to reinvest in
    IERC20 public investmentToken;

    // ERC20 token used for dividends
    IERC20 public dividendToken;

    // Minimum reinvestment amount
    uint256 public minimumReinvestmentAmount;

    // Event declarations
    event DividendsDeposited(address indexed user, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 amount, uint256 tokensReceived);
    event MinimumReinvestmentAmountUpdated(uint256 oldAmount, uint256 newAmount);

    // Constructor to initialize the contract with ERC20 tokens
    constructor(address _investmentToken, address _dividendToken, uint256 _minimumReinvestmentAmount) {
        investmentToken = IERC20(_investmentToken);
        dividendToken = IERC20(_dividendToken);
        minimumReinvestmentAmount = _minimumReinvestmentAmount;
    }

    // Function to deposit dividends
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        dividendToken.transferFrom(msg.sender, address(this), amount);
        userBalances[msg.sender] = userBalances[msg.sender].add(amount);

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function to reinvest profits into the investment token
    function reinvestProfits() external whenNotPaused nonReentrant {
        uint256 balance = userBalances[msg.sender];
        require(balance >= minimumReinvestmentAmount, "Insufficient balance to reinvest");

        // Calculate the number of investment tokens to purchase
        uint256 tokensToReceive = calculateTokensReceived(balance);

        // Transfer investment tokens to the user
        require(investmentToken.transfer(msg.sender, tokensToReceive), "Investment token transfer failed");

        // Update the user balance
        userBalances[msg.sender] = 0;

        emit ProfitsReinvested(msg.sender, balance, tokensToReceive);
    }

    // Function to calculate the number of tokens received for reinvestment
    function calculateTokensReceived(uint256 amount) public view returns (uint256) {
        // Here, assume a 1:1 ratio for simplicity, but this can be modified
        return amount;
    }

    // Function to update the minimum reinvestment amount
    function updateMinimumReinvestmentAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "New amount must be greater than zero");
        uint256 oldAmount = minimumReinvestmentAmount;
        minimumReinvestmentAmount = newAmount;

        emit MinimumReinvestmentAmountUpdated(oldAmount, newAmount);
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
