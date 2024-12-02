// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract YieldOptimizationAndRebalancing is ERC4626, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // Strategy structure
    struct YieldStrategy {
        uint256 targetAllocation; // Target percentage in basis points (1% = 100 bp)
        address strategyAddress;  // Address of the strategy contract
        bool isActive;            // Status of the strategy
    }

    // List of strategies
    YieldStrategy[] public strategies;

    // Minimum performance threshold for rebalancing (in basis points, 1% = 100)
    uint256 public performanceThreshold;

    // Oracle for market data (e.g., Chainlink)
    AggregatorV3Interface public priceOracle;

    // Events
    event StrategyAdded(uint256 indexed strategyId, address indexed strategyAddress, uint256 targetAllocation);
    event StrategyRemoved(uint256 indexed strategyId);
    event Rebalanced(address indexed initiator);
    event PerformanceThresholdUpdated(uint256 newThreshold);

    // Constructor
    constructor(IERC20 _asset, uint256 _initialThreshold, address _priceOracle)
        ERC20("YieldOptimizedVaultToken", "YOVT")
        ERC4626(_asset)
    {
        performanceThreshold = _initialThreshold;
        priceOracle = AggregatorV3Interface(_priceOracle);
    }

    // Modifier to check if allocation is valid
    modifier validAllocation() {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].isActive) {
                totalAllocation = totalAllocation.add(strategies[i].targetAllocation);
            }
        }
        require(totalAllocation <= 10000, "Total allocation must be <= 100%");
        _;
    }

    // Function to add a new strategy
    function addStrategy(address _strategyAddress, uint256 _targetAllocation) external onlyOwner validAllocation {
        strategies.push(YieldStrategy({
            targetAllocation: _targetAllocation,
            strategyAddress: _strategyAddress,
            isActive: true
        }));
        emit StrategyAdded(strategies.length - 1, _strategyAddress, _targetAllocation);
    }

    // Function to remove a strategy
    function removeStrategy(uint256 _strategyId) external onlyOwner {
        require(_strategyId < strategies.length, "Invalid strategy ID");
        strategies[_strategyId].isActive = false;
        emit StrategyRemoved(_strategyId);
    }

    // Function to update the performance threshold
    function updatePerformanceThreshold(uint256 _newThreshold) external onlyOwner {
        performanceThreshold = _newThreshold;
        emit PerformanceThresholdUpdated(_newThreshold);
    }

    // Function to rebalance the portfolio
    function rebalance() external onlyOwner nonReentrant validAllocation whenNotPaused {
        uint256 totalValue = totalAssets();
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].isActive) {
                uint256 targetValue = totalValue.mul(strategies[i].targetAllocation).div(10000);
                _adjustStrategyAllocation(strategies[i].strategyAddress, targetValue);
            }
        }
        emit Rebalanced(msg.sender);
    }

    // Internal function to adjust strategy allocation
    function _adjustStrategyAllocation(address _strategyAddress, uint256 _targetValue) internal {
        // Custom logic to adjust strategy allocation
        // Can include depositing/withdrawing assets based on strategy performance
    }

    // Function to get the latest market price from the oracle
    function getLatestPrice() public view returns (int256) {
        (,int256 price,,,) = priceOracle.latestRoundData();
        return price;
    }

    // Overriding ERC4626 functions to include pause functionality
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override whenNotPaused returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    // Emergency pause function
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause function
    function unpause() external onlyOwner {
        _unpause();
    }
}
