// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC4626 {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}

contract ETFVaultToken is ERC20Burnable, Ownable, Pausable, IERC4626 {
    // Total assets managed by the vault
    uint256 private _totalAssets;
    // Yield accrued for each staked token
    mapping(address => uint256) private _stakingBalance;
    mapping(address => uint256) private _yieldAccrued;

    // Events
    event YieldDistributed(address indexed staker, uint256 amount);
    
    constructor() ERC20("ETF Vault Token", "EVT") {}

    // Deposit assets into the vault
    function deposit(uint256 assets, address receiver) external override whenNotPaused returns (uint256 shares) {
        shares = (totalSupply() == 0) ? assets : (assets * totalSupply()) / totalAssets();
        _mint(receiver, shares);
        _totalAssets += assets;
        return shares;
    }

    // Withdraw assets from the vault
    function withdraw(uint256 shares, address receiver, address owner) external override whenNotPaused returns (uint256 assets) {
        require(balanceOf(owner) >= shares, "Insufficient shares");
        assets = convertToAssets(shares);
        _burn(owner, shares);
        _totalAssets -= assets;
        return assets;
    }

    // Get total assets managed by the vault
    function totalAssets() public view override returns (uint256) {
        return _totalAssets;
    }

    // Convert assets to shares
    function convertToShares(uint256 assets) public view override returns (uint256) {
        return (totalSupply() == 0) ? assets : (assets * totalSupply()) / totalAssets();
    }

    // Convert shares to assets
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return (shares * totalAssets()) / totalSupply();
    }

    // Stake tokens to earn yield
    function stake(uint256 amount) external whenNotPaused {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _stakingBalance[msg.sender] += amount;
        _yieldAccrued[msg.sender] += calculateYield(amount);
        _transfer(msg.sender, address(this), amount);
    }

    // Unstake tokens and claim yield
    function unstake(uint256 amount) external whenNotPaused {
        require(_stakingBalance[msg.sender] >= amount, "Insufficient staked balance");
        _stakingBalance[msg.sender] -= amount;
        _yieldAccrued[msg.sender] += calculateYield(amount);
        _transfer(address(this), msg.sender, amount);
        emit YieldDistributed(msg.sender, _yieldAccrued[msg.sender]);
        _yieldAccrued[msg.sender] = 0; // Reset yield after distribution
    }

    // Calculate yield based on staked amount (stub logic for example)
    function calculateYield(uint256 amount) internal view returns (uint256) {
        // Implement yield calculation based on underlying assets' performance
        return amount * 10 / 100; // Example: 10% yield
    }

    // Function to pause contract operations
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause contract operations
    function unpause() external onlyOwner {
        _unpause();
    }
}
