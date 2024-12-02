// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProfitDrivenReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // ERC20 token for reinvestment and dividend distribution
    IERC20 public investmentToken;
    IERC20 public dividendToken;

    // Minimum profit threshold for reinvestment
    uint256 public profitThreshold;

    // Mapping to store user dividend balances
    mapping(address => uint256) public userDividendBalances;

    // Event declarations
    event DividendsDeposited(address indexed user, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 reinvestedAmount, uint256 remainingAmount);
    event ProfitThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    // Constructor to initialize the contract with ERC20 tokens and a default profit threshold
    constructor(address _investmentToken, address _dividendToken, uint256 _profitThreshold) {
        require(_profitThreshold > 0, "Profit threshold must be greater than zero");
        investmentToken = IERC20(_investmentToken);
        dividendToken = IERC20(_dividendToken);
        profitThreshold = _profitThreshold;
    }

    // Function to deposit dividends
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        dividendToken.transferFrom(msg.sender, address(this), amount);
        userDividendBalances[msg.sender] = userDividendBalances[msg.sender].add(amount);

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function to reinvest profits if they exceed the profit threshold
    function reinvestProfits() external whenNotPaused nonReentrant {
        uint256 dividendBalance = userDividendBalances[msg.sender];
        require(dividendBalance >= profitThreshold, "Insufficient profit for reinvestment");

        // Reinvest the entire dividend balance into the investment token
        require(investmentToken.transfer(msg.sender, dividendBalance), "Reinvestment failed");

        emit ProfitsReinvested(msg.sender, dividendBalance, 0);

        // Reset user balance after reinvestment
        userDividendBalances[msg.sender] = 0;
    }

    // Function to update the profit threshold (admin only)
    function updateProfitThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be greater than zero");
        uint256 oldThreshold = profitThreshold;
        profitThreshold = newThreshold;

        emit ProfitThresholdUpdated(oldThreshold, newThreshold);
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
