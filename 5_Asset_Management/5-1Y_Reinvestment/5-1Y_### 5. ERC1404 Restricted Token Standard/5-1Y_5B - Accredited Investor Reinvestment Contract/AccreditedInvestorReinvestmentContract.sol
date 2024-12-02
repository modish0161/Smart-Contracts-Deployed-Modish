// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";

contract AccreditedInvestorReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    ERC1404 public restrictedToken;
    mapping(address => uint256) public dividendBalances;
    mapping(address => bool) public accreditedInvestors;

    event DividendsDeposited(address indexed investor, uint256 amount);
    event DividendsReinvested(address indexed investor, uint256 amount, uint256 reinvestedAmount);
    event ReinvestmentStrategyUpdated(address indexed investor, uint256 percentage);
    event RestrictedTokenUpdated(address indexed tokenAddress);
    event InvestorAccredited(address indexed investor, bool status);

    struct ReinvestmentStrategy {
        uint256 percentage; // Percentage of dividends to reinvest
    }

    mapping(address => ReinvestmentStrategy) public reinvestmentStrategies;

    modifier onlyAccreditedInvestor() {
        require(accreditedInvestors[msg.sender], "Investor is not accredited");
        _;
    }

    constructor(address _restrictedToken) {
        require(_restrictedToken != address(0), "Invalid restricted token address");
        restrictedToken = ERC1404(_restrictedToken);
    }

    // Function to deposit dividends into the contract
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant onlyAccreditedInvestor {
        require(amount > 0, "Amount must be greater than zero");
        restrictedToken.transferFrom(msg.sender, address(this), amount);
        dividendBalances[msg.sender] = dividendBalances[msg.sender].add(amount);

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function to set reinvestment strategy
    function setReinvestmentStrategy(uint256 percentage) external whenNotPaused onlyAccreditedInvestor {
        require(percentage <= 100, "Percentage cannot exceed 100");

        reinvestmentStrategies[msg.sender] = ReinvestmentStrategy({
            percentage: percentage
        });

        emit ReinvestmentStrategyUpdated(msg.sender, percentage);
    }

    // Function to reinvest dividends based on user's reinvestment strategy
    function reinvestDividends() external whenNotPaused nonReentrant onlyAccreditedInvestor {
        uint256 availableDividends = dividendBalances[msg.sender];
        require(availableDividends > 0, "No dividends available to reinvest");

        ReinvestmentStrategy memory strategy = reinvestmentStrategies[msg.sender];
        uint256 reinvestAmount = availableDividends.mul(strategy.percentage).div(100);
        uint256 remainingDividends = availableDividends.sub(reinvestAmount);

        require(restrictedToken.transfer(msg.sender, reinvestAmount), "Reinvestment failed");

        dividendBalances[msg.sender] = remainingDividends;

        emit DividendsReinvested(msg.sender, availableDividends, reinvestAmount);
    }

    // Function to update the restricted token address
    function updateRestrictedToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        restrictedToken = ERC1404(newTokenAddress);

        emit RestrictedTokenUpdated(newTokenAddress);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to withdraw dividends manually
    function withdrawDividends(uint256 amount) external nonReentrant onlyAccreditedInvestor {
        require(dividendBalances[msg.sender] >= amount, "Insufficient dividends");
        dividendBalances[msg.sender] = dividendBalances[msg.sender].sub(amount);
        restrictedToken.transfer(msg.sender, amount);
    }

    // Function to check if the user is compliant before any transfer or reinvestment
    function isTransferRestricted(address investor, uint256 amount) external view returns (bool) {
        uint8 restrictionCode = restrictedToken.detectTransferRestriction(investor, address(this), amount);
        return restrictionCode != 0; // 0 means no restriction
    }

    // Function to add or remove an accredited investor
    function setAccreditedInvestor(address investor, bool status) external onlyOwner {
        accreditedInvestors[investor] = status;
        emit InvestorAccredited(investor, status);
    }
}
