// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BasicPortfolioManagement is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Structure to hold asset details
    struct Asset {
        IERC20 token;
        uint256 targetAllocation; // Target percentage (in basis points, 1% = 100 bp)
    }

    // Array to hold all assets in the portfolio
    Asset[] public assets;

    // Mapping to track investor balances in the portfolio
    mapping(address => uint256) public balances;

    // Total value of the portfolio in wei
    uint256 public totalPortfolioValue;

    // Events
    event Invested(address indexed investor, uint256 amount);
    event Withdrawn(address indexed investor, uint256 amount);
    event Rebalanced();
    event AssetAdded(IERC20 indexed token, uint256 targetAllocation);
    event AssetUpdated(IERC20 indexed token, uint256 newTargetAllocation);

    // Modifier to check that the total target allocation is 100%
    modifier validAllocation() {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            totalAllocation = totalAllocation.add(assets[i].targetAllocation);
        }
        require(totalAllocation == 10000, "Total allocation must be 100%");
        _;
    }

    // Function to add a new asset to the portfolio
    function addAsset(IERC20 _token, uint256 _targetAllocation) external onlyOwner validAllocation {
        assets.push(Asset({ token: _token, targetAllocation: _targetAllocation }));
        emit AssetAdded(_token, _targetAllocation);
    }

    // Function to update the target allocation of an existing asset
    function updateAsset(IERC20 _token, uint256 _newTargetAllocation) external onlyOwner validAllocation {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == _token) {
                assets[i].targetAllocation = _newTargetAllocation;
                emit AssetUpdated(_token, _newTargetAllocation);
                return;
            }
        }
    }

    // Function for investors to invest ETH into the portfolio
    function invest() external payable nonReentrant {
        require(msg.value > 0, "Investment amount must be greater than zero");
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalPortfolioValue = totalPortfolioValue.add(msg.value);
        emit Invested(msg.sender, msg.value);
    }

    // Function for investors to withdraw their investment
    function withdraw(uint256 _amount) external nonReentrant {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalPortfolioValue = totalPortfolioValue.sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    // Function to rebalance the portfolio based on the target allocations
    function rebalance() external onlyOwner nonReentrant validAllocation {
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 targetValue = totalPortfolioValue.mul(assets[i].targetAllocation).div(10000);
            uint256 currentBalance = assets[i].token.balanceOf(address(this));

            if (currentBalance > targetValue) {
                // Sell excess tokens
                uint256 excessAmount = currentBalance.sub(targetValue);
                assets[i].token.transfer(owner(), excessAmount);
            } else if (currentBalance < targetValue) {
                // Buy more tokens
                uint256 deficitAmount = targetValue.sub(currentBalance);
                assets[i].token.transferFrom(owner(), address(this), deficitAmount);
            }
        }
        emit Rebalanced();
    }

    // Function to view the target allocation of a specific asset
    function getAssetAllocation(IERC20 _token) external view returns (uint256) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == _token) {
                return assets[i].targetAllocation;
            }
        }
        return 0; // Asset not found
    }

    // Fallback function to handle ETH sent directly to the contract
    receive() external payable {
        invest();
    }
}
