// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HedgeFundVaultToken is ERC4626, Ownable, ReentrancyGuard {
    // Mapping for asset management
    mapping(address => uint256) public totalInvested;
    mapping(address => uint256) public totalWithdrawn;

    event Deposited(address indexed investor, uint256 amount);
    event Withdrawn(address indexed investor, uint256 amount);
    event SharesMinted(address indexed investor, uint256 shares);
    event SharesBurned(address indexed investor, uint256 shares);

    constructor(IERC20 asset) ERC4626(asset) {}

    // Deposit funds into the vault
    function deposit(uint256 assets, address to) public nonReentrant returns (uint256 shares) {
        shares = super.deposit(assets, to);
        totalInvested[to] += assets;

        emit Deposited(to, assets);
        emit SharesMinted(to, shares);
    }

    // Withdraw funds from the vault
    function withdraw(uint256 assets, address to, address from) public nonReentrant returns (uint256 shares) {
        shares = super.withdraw(assets, to, from);
        totalWithdrawn[from] += assets;

        emit Withdrawn(from, assets);
        emit SharesBurned(from, shares);
    }

    // Override the 'convertToShares' method to provide share calculations
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        shares = super.convertToShares(assets);
    }

    // Override the 'convertToAssets' method to provide asset calculations
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        assets = super.convertToAssets(shares);
    }

    // Get total investments made by an investor
    function getTotalInvested(address investor) public view returns (uint256) {
        return totalInvested[investor];
    }

    // Get total withdrawals made by an investor
    function getTotalWithdrawn(address investor) public view returns (uint256) {
        return totalWithdrawn[investor];
    }
}
