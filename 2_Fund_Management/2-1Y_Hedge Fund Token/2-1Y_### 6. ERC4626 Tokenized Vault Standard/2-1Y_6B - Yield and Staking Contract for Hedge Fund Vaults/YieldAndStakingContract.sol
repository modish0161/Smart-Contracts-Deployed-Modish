// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YieldAndStakingContract is ERC4626, Ownable, ReentrancyGuard {
    // Mapping to store staking balances
    mapping(address => uint256) public stakedAmount;

    // Annual yield percentage (in basis points)
    uint256 public annualYieldBPS; // Basis Points for yield

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event YieldUpdated(uint256 newYield);

    constructor(IERC20 asset, uint256 initialYieldBPS) ERC4626(asset) {
        annualYieldBPS = initialYieldBPS;
    }

    // Stake tokens in the vault
    function stake(uint256 assets) public nonReentrant {
        require(assets > 0, "Cannot stake 0");
        
        // Transfer tokens to this contract
        asset().transferFrom(msg.sender, address(this), assets);
        
        // Mint shares for the user
        uint256 shares = deposit(assets, msg.sender);
        stakedAmount[msg.sender] += assets;

        emit Staked(msg.sender, assets);
    }

    // Unstake tokens from the vault
    function unstake(uint256 assets) public nonReentrant {
        require(stakedAmount[msg.sender] >= assets, "Insufficient staked amount");
        
        // Withdraw assets
        withdraw(assets, msg.sender, msg.sender);
        stakedAmount[msg.sender] -= assets;

        emit Unstaked(msg.sender, assets);
    }

    // Calculate yield for a user based on their staked amount
    function calculateYield(address user) public view returns (uint256) {
        return (stakedAmount[user] * annualYieldBPS) / 10000; // Yield in tokens
    }

    // Update the annual yield percentage
    function setAnnualYield(uint256 newYieldBPS) external onlyOwner {
        annualYieldBPS = newYieldBPS;
        emit YieldUpdated(newYieldBPS);
    }

    // Override the 'convertToShares' method for share calculations
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        shares = super.convertToShares(assets);
    }

    // Override the 'convertToAssets' method for asset calculations
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        assets = super.convertToAssets(shares);
    }
}
