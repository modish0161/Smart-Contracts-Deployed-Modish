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

    constructor() ERC20("ETF Vault Token", "EVT") {}

    // Deposit assets into the vault
    function deposit(uint256 assets, address receiver) external override whenNotPaused returns (uint256 shares) {
        // Calculate shares to mint based on the amount of assets deposited
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

    // Function to pause contract operations
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause contract operations
    function unpause() external onlyOwner {
        _unpause();
    }
}
