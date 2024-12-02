// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PooledAssetRebalancing is ERC4626, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // Struct to hold the rebalancing strategies
    struct RebalancingStrategy {
        uint256 targetAllocation; // Target allocation percentage in basis points (1% = 100)
        address asset;            // Address of the asset to be rebalanced
        bool isActive;            // Status of the strategy
    }

    // Array to store all the rebalancing strategies
    RebalancingStrategy[] public strategies;

    // Performance threshold for triggering rebalancing
    uint256 public rebalancingThreshold;

    // Events
    event StrategyAdded(uint256 indexed strategyId, address indexed asset, uint256 targetAllocation);
    event StrategyRemoved(uint256 indexed strategyId);
    event Rebalanced(address indexed initiator);
    event ThresholdUpdated(uint256 newThreshold);

    // Constructor
    constructor(IERC20 _asset, uint256 _initialThreshold)
        ERC20("PooledAssetVaultToken", "PAVT")
        ERC4626(_asset)
    {
        rebalancingThreshold = _initialThreshold;
    }

    // Modifier to validate that total allocation doesn't exceed 100%
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

    // Add a new rebalancing strategy
    function addStrategy(address _asset, uint256 _targetAllocation) external onlyOwner validAllocation {
        strategies.push(RebalancingStrategy({
            targetAllocation: _targetAllocation,
            asset: _asset,
            isActive: true
        }));
        emit StrategyAdded(strategies.length - 1, _asset, _targetAllocation);
    }

    // Remove a rebalancing strategy
    function removeStrategy(uint256 _strategyId) external onlyOwner {
        require(_strategyId < strategies.length, "Invalid strategy ID");
        strategies[_strategyId].isActive = false;
        emit StrategyRemoved(_strategyId);
    }

    // Update rebalancing threshold
    function updateRebalancingThreshold(uint256 _newThreshold) external onlyOwner {
        rebalancingThreshold = _newThreshold;
        emit ThresholdUpdated(_newThreshold);
    }

    // Rebalance the pooled assets based on predefined strategies
    function rebalance() external onlyOwner nonReentrant validAllocation whenNotPaused {
        uint256 totalValue = totalAssets();
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].isActive) {
                uint256 targetValue = totalValue.mul(strategies[i].targetAllocation).div(10000);
                _adjustAssetAllocation(strategies[i].asset, targetValue);
            }
        }
        emit Rebalanced(msg.sender);
    }

    // Internal function to adjust asset allocation
    function _adjustAssetAllocation(address _asset, uint256 _targetValue) internal {
        // Custom logic to adjust asset allocation
        // Implement strategies to buy/sell assets or interact with DeFi protocols
    }

    // Pausing and unpausing functions for emergency control
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Override deposit function to include pause functionality
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    // Override withdraw function to include pause functionality
    function withdraw(uint256 assets, address receiver, address owner) public override whenNotPaused returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }
}
