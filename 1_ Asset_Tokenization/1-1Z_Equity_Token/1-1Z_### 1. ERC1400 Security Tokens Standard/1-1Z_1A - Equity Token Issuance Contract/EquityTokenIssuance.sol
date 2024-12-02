// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Equity Token Issuance Contract
/// @notice This contract issues, manages, and governs equity tokens representing shares in a company.
contract EquityTokenIssuance is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Token interface for ERC20 compliance
    IERC20 public equityToken;

    // Minimum investment amount
    uint256 public minimumInvestment;

    // Maximum investment amount
    uint256 public maximumInvestment;

    // Total tokens available for sale
    uint256 public totalTokensForSale;

    // Price per token in wei
    uint256 public tokenPrice;

    // Mapping of investors to their allocated tokens
    mapping(address => uint256) public investorAllocations;

    // Set of investors who have invested
    EnumerableSet.AddressSet private investors;

    // Event emitted when an investment is made
    event Invested(address indexed investor, uint256 amount, uint256 tokenAmount);

    // Event emitted when tokens are claimed
    event TokensClaimed(address indexed investor, uint256 tokenAmount);

    // Event emitted when funds are withdrawn
    event FundsWithdrawn(address indexed admin, uint256 amount);

    // Modifier to check if the caller is an investor
    modifier onlyInvestor() {
        require(investorAllocations[msg.sender] > 0, "Caller is not an investor");
        _;
    }

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC20 token representing the equity
    /// @param _minimumInvestment Minimum amount of tokens required to invest
    /// @param _maximumInvestment Maximum amount of tokens an individual can invest
    /// @param _totalTokensForSale Total number of tokens available for sale
    /// @param _tokenPrice Price per token in wei
    constructor(
        IERC20 _equityToken,
        uint256 _minimumInvestment,
        uint256 _maximumInvestment,
        uint256 _totalTokensForSale,
        uint256 _tokenPrice
    ) {
        equityToken = _equityToken;
        minimumInvestment = _minimumInvestment;
        maximumInvestment = _maximumInvestment;
        totalTokensForSale = _totalTokensForSale;
        tokenPrice = _tokenPrice;
    }

    /// @notice Invest in the equity tokens
    /// @dev Emits an `Invested` event on success
    function invest() external payable whenNotPaused nonReentrant {
        uint256 weiAmount = msg.value;
        require(weiAmount >= minimumInvestment, "Investment amount is below minimum");
        require(weiAmount <= maximumInvestment, "Investment amount is above maximum");
        
        uint256 tokenAmount = weiAmount.div(tokenPrice);
        require(totalTokensForSale >= tokenAmount, "Not enough tokens available for sale");

        totalTokensForSale = totalTokensForSale.sub(tokenAmount);
        investorAllocations[msg.sender] = investorAllocations[msg.sender].add(tokenAmount);

        investors.add(msg.sender);

        emit Invested(msg.sender, weiAmount, tokenAmount);
    }

    /// @notice Claim allocated tokens after the sale
    /// @dev Only callable by the investor
    function claimTokens() external onlyInvestor whenNotPaused nonReentrant {
        uint256 tokenAmount = investorAllocations[msg.sender];
        require(tokenAmount > 0, "No tokens to claim");

        investorAllocations[msg.sender] = 0;
        equityToken.transfer(msg.sender, tokenAmount);

        emit TokensClaimed(msg.sender, tokenAmount);
    }

    /// @notice Withdraw invested funds
    /// @dev Only callable by the contract owner
    function withdrawFunds() external onlyOwner whenNotPaused nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");

        Address.sendValue(payable(owner()), contractBalance);

        emit FundsWithdrawn(owner(), contractBalance);
    }

    /// @notice Pause the contract
    /// @dev Only callable by the contract owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only callable by the contract owner
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the total number of investors
    /// @return uint256 Number of investors
    function getInvestorCount() external view returns (uint256) {
        return investors.length();
    }

    /// @notice Check if an address is an investor
    /// @param investor Address to check
    /// @return bool True if the address is an investor, false otherwise
    function isInvestor(address investor) external view returns (bool) {
        return investors.contains(investor);
    }

    /// @notice Get the allocated tokens for an investor
    /// @param investor Address of the investor
    /// @return uint256 Amount of allocated tokens
    function getAllocation(address investor) external view returns (uint256) {
        return investorAllocations[investor];
    }

    /// @notice Set a new minimum investment amount
    /// @param newMinimumInvestment New minimum investment amount in wei
    function setMinimumInvestment(uint256 newMinimumInvestment) external onlyOwner {
        minimumInvestment = newMinimumInvestment;
    }

    /// @notice Set a new maximum investment amount
    /// @param newMaximumInvestment New maximum investment amount in wei
    function setMaximumInvestment(uint256 newMaximumInvestment) external onlyOwner {
        maximumInvestment = newMaximumInvestment;
    }

    /// @notice Set a new token price
    /// @param newTokenPrice New token price in wei
    function setTokenPrice(uint256 newTokenPrice) external onlyOwner {
        tokenPrice = newTokenPrice;
    }
}
