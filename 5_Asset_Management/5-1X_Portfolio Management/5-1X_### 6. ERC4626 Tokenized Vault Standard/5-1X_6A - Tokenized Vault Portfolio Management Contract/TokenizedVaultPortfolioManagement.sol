// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenizedVaultPortfolioManagement is ERC4626, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    struct VaultStrategy {
        uint256 targetAllocation;     // Target percentage in basis points (1% = 100 bp)
        address strategyAddress;      // Address of the strategy contract
        bool isActive;                // Status of the strategy
    }

    // Array of vault strategies
    VaultStrategy[] public vaultStrategies;

    // Events
    event StrategyAdded(uint256 indexed strategyId, address indexed strategyAddress, uint256 targetAllocation);
    event StrategyRemoved(uint256 indexed strategyId);
    event Rebalanced(address indexed initiator);

    // Modifiers
    modifier validAllocation() {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < vaultStrategies.length; i++) {
            if (vaultStrategies[i].isActive) {
                totalAllocation = totalAllocation.add(vaultStrategies[i].targetAllocation);
            }
        }
        require(totalAllocation <= 10000, "Total allocation must be <= 100%");
        _;
    }

    constructor(IERC20 _asset)
        ERC20("TokenizedVaultPortfolioToken", "TVPT")
        ERC4626(_asset) 
    {
        // Initial setup if needed
    }

    function addStrategy(address _strategyAddress, uint256 _targetAllocation) external onlyOwner validAllocation {
        vaultStrategies.push(VaultStrategy({
            targetAllocation: _targetAllocation,
            strategyAddress: _strategyAddress,
            isActive: true
        }));
        emit StrategyAdded(vaultStrategies.length - 1, _strategyAddress, _targetAllocation);
    }

    function removeStrategy(uint256 _strategyId) external onlyOwner {
        require(_strategyId < vaultStrategies.length, "Invalid strategy ID");
        vaultStrategies[_strategyId].isActive = false;
        emit StrategyRemoved(_strategyId);
    }

    function rebalance() external onlyOwner nonReentrant validAllocation whenNotPaused {
        uint256 totalValue = totalAssets();
        for (uint256 i = 0; i < vaultStrategies.length; i++) {
            if (vaultStrategies[i].isActive) {
                uint256 targetValue = totalValue.mul(vaultStrategies[i].targetAllocation).div(10000);
                _adjustStrategyAllocation(vaultStrategies[i].strategyAddress, targetValue);
            }
        }
        emit Rebalanced(msg.sender);
    }

    function _adjustStrategyAllocation(address _strategyAddress, uint256 _targetValue) internal {
        // Logic to adjust the strategy allocation
        // This would typically involve depositing/withdrawing assets to/from strategy
    }

    // Emergency function to pause all operations
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause all operations
    function unpause() external onlyOwner {
        _unpause();
    }

    // Overriding ERC4626 functions
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override whenNotPaused returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }
}
