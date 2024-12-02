// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BatchReinvestmentContract is IERC1155Receiver, Ownable, ReentrancyGuard, Pausable {
    using Address for address;

    // ERC1155 Token Interface
    IERC1155 public investmentToken;

    // Performance Metrics Oracle Interface
    AggregatorV3Interface public performanceOracle;

    // Mapping to store user balances for each token ID
    mapping(address => mapping(uint256 => uint256)) public userTokenBalances;

    // Reinvestment Strategies
    mapping(address => ReinvestmentStrategy) public reinvestmentStrategies;

    // Struct to define a reinvestment strategy
    struct ReinvestmentStrategy {
        uint256[] tokenIds;
        uint256[] percentages; // Percentages for each tokenId to be reinvested
    }

    // Event declarations
    event ProfitsDeposited(address indexed user, uint256 tokenId, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 totalAmount, uint256[] tokenIds, uint256[] amounts);
    event ReinvestmentStrategyUpdated(address indexed user, uint256[] tokenIds, uint256[] percentages);
    event OracleUpdated(address indexed oracle);
    event InvestmentTokenUpdated(address indexed tokenAddress);

    // Constructor to initialize the contract with the investment token and oracle address
    constructor(address _investmentToken, address _performanceOracle) {
        require(_investmentToken != address(0), "Invalid investment token address");
        require(_performanceOracle != address(0), "Invalid oracle address");

        investmentToken = IERC1155(_investmentToken);
        performanceOracle = AggregatorV3Interface(_performanceOracle);
    }

    // Function to deposit profits (ERC1155 tokens)
    function depositProfits(uint256 tokenId, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        investmentToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        userTokenBalances[msg.sender][tokenId] += amount;

        emit ProfitsDeposited(msg.sender, tokenId, amount);
    }

    // Function to set reinvestment strategy for the user
    function setReinvestmentStrategy(uint256[] calldata tokenIds, uint256[] calldata percentages) external whenNotPaused {
        require(tokenIds.length == percentages.length, "Token IDs and percentages length mismatch");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }
        require(totalPercentage == 100, "Total percentage must equal 100");

        reinvestmentStrategies[msg.sender] = ReinvestmentStrategy({
            tokenIds: tokenIds,
            percentages: percentages
        });

        emit ReinvestmentStrategyUpdated(msg.sender, tokenIds, percentages);
    }

    // Function to batch reinvest profits based on the user's strategy
    function batchReinvestProfits(uint256 tokenId, uint256 amount) external whenNotPaused nonReentrant {
        require(userTokenBalances[msg.sender][tokenId] >= amount, "Insufficient balance for reinvestment");

        ReinvestmentStrategy memory strategy = reinvestmentStrategies[msg.sender];
        require(strategy.tokenIds.length > 0, "Reinvestment strategy not set");

        uint256 totalReinvested = 0;
        uint256[] memory reinvestAmounts = new uint256[](strategy.tokenIds.length);

        for (uint256 i = 0; i < strategy.tokenIds.length; i++) {
            uint256 reinvestAmount = (amount * strategy.percentages[i]) / 100;
            investmentToken.safeTransferFrom(address(this), msg.sender, strategy.tokenIds[i], reinvestAmount, "");
            reinvestAmounts[i] = reinvestAmount;
            totalReinvested += reinvestAmount;
        }

        userTokenBalances[msg.sender][tokenId] -= amount;

        emit ProfitsReinvested(msg.sender, totalReinvested, strategy.tokenIds, reinvestAmounts);
    }

    // Function to update the performance oracle
    function updateOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address");
        performanceOracle = AggregatorV3Interface(newOracle);
        emit OracleUpdated(newOracle);
    }

    // Function to update the investment token address
    function updateInvestmentToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        investmentToken = IERC1155(newTokenAddress);
        emit InvestmentTokenUpdated(newTokenAddress);
    }

    // ERC1155Receiver hook to allow this contract to receive ERC1155 tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    // ERC1155Receiver hook for batch token transfers
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
