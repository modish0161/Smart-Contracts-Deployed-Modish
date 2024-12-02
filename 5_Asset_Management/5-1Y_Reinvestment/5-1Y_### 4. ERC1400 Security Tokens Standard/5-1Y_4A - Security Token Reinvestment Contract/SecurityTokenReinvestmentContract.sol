// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SecurityTokenReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    // ERC1400 Token Interface
    ERC1400 public securityToken;

    // Performance Metrics Oracle Interface
    AggregatorV3Interface public performanceOracle;

    // Mapping to store user balances for each partition
    mapping(address => mapping(bytes32 => uint256)) public userTokenBalances;

    // Reinvestment Strategy
    mapping(address => ReinvestmentStrategy) public reinvestmentStrategies;

    // Struct to define a reinvestment strategy
    struct ReinvestmentStrategy {
        bytes32[] partitions; // Token partitions to reinvest into
        uint256[] percentages; // Percentages for each partition
    }

    // Event declarations
    event ProfitsDeposited(address indexed user, bytes32 partition, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 totalAmount, bytes32[] partitions, uint256[] amounts);
    event ReinvestmentStrategyUpdated(address indexed user, bytes32[] partitions, uint256[] percentages);
    event OracleUpdated(address indexed oracle);
    event SecurityTokenUpdated(address indexed tokenAddress);

    // Constructor to initialize the contract with the security token and oracle address
    constructor(address _securityToken, address _performanceOracle) {
        require(_securityToken != address(0), "Invalid security token address");
        require(_performanceOracle != address(0), "Invalid oracle address");

        securityToken = ERC1400(_securityToken);
        performanceOracle = AggregatorV3Interface(_performanceOracle);
    }

    // Function to deposit profits (ERC1400 tokens)
    function depositProfits(bytes32 partition, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        securityToken.operatorTransferByPartition(partition, msg.sender, address(this), amount, "", "");
        userTokenBalances[msg.sender][partition] += amount;

        emit ProfitsDeposited(msg.sender, partition, amount);
    }

    // Function to set reinvestment strategy for the user
    function setReinvestmentStrategy(bytes32[] calldata partitions, uint256[] calldata percentages) external whenNotPaused {
        require(partitions.length == percentages.length, "Partitions and percentages length mismatch");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }
        require(totalPercentage == 100, "Total percentage must equal 100");

        reinvestmentStrategies[msg.sender] = ReinvestmentStrategy({
            partitions: partitions,
            percentages: percentages
        });

        emit ReinvestmentStrategyUpdated(msg.sender, partitions, percentages);
    }

    // Function to batch reinvest profits based on the user's strategy
    function batchReinvestProfits(bytes32 partition, uint256 amount) external whenNotPaused nonReentrant {
        require(userTokenBalances[msg.sender][partition] >= amount, "Insufficient balance for reinvestment");

        ReinvestmentStrategy memory strategy = reinvestmentStrategies[msg.sender];
        require(strategy.partitions.length > 0, "Reinvestment strategy not set");

        uint256 totalReinvested = 0;
        uint256[] memory reinvestAmounts = new uint256[](strategy.partitions.length);

        for (uint256 i = 0; i < strategy.partitions.length; i++) {
            uint256 reinvestAmount = (amount * strategy.percentages[i]) / 100;
            securityToken.operatorTransferByPartition(partition, address(this), msg.sender, reinvestAmount, "", "");
            reinvestAmounts[i] = reinvestAmount;
            totalReinvested += reinvestAmount;
        }

        userTokenBalances[msg.sender][partition] -= amount;

        emit ProfitsReinvested(msg.sender, totalReinvested, strategy.partitions, reinvestAmounts);
    }

    // Function to update the performance oracle
    function updateOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address");
        performanceOracle = AggregatorV3Interface(newOracle);
        emit OracleUpdated(newOracle);
    }

    // Function to update the security token address
    function updateSecurityToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        securityToken = ERC1400(newTokenAddress);
        emit SecurityTokenUpdated(newTokenAddress);
    }

    // Function to pause the contract (admin only)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (admin only)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to transfer ownership of the contract
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        _transferOwnership(newOwner);
    }
}
