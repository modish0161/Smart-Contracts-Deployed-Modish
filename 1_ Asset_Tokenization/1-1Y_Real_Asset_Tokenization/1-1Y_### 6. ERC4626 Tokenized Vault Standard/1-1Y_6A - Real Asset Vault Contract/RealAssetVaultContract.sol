// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

/// @title Real Asset Vault Contract
/// @notice Tokenizes a vault containing multiple real assets, such as property, commodities, or other tangible investments.
/// @dev Implements ERC4626 standard for tokenized vaults, with ERC20 for fractional ownership.
contract RealAssetVaultContract is ERC4626, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ERC20 token used for the vault (representing shares)
    ERC20 private vaultToken;

    // Minimum amount required to invest in the vault
    uint256 public minInvestment;

    // Events
    event VaultDeposit(address indexed investor, uint256 amount, uint256 shares);
    event VaultWithdrawal(address indexed investor, uint256 amount, uint256 shares);
    event MinimumInvestmentChanged(uint256 newMinInvestment);

    /// @dev Constructor to set token details and initial minimum investment
    /// @param _vaultToken Address of the ERC20 token representing fractional ownership of the vault
    /// @param _minInvestment Minimum investment required to participate in the vault
    constructor(ERC20 _vaultToken, uint256 _minInvestment) ERC4626(_vaultToken, "Real Asset Vault Share", "RAVS") {
        vaultToken = _vaultToken;
        minInvestment = _minInvestment;
    }

    /// @notice Deposit assets into the vault and receive shares
    /// @param assets The amount of assets to deposit
    /// @param receiver The address of the receiver of the shares
    /// @return shares The amount of shares received
    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256 shares) {
        require(assets >= minInvestment, "Investment amount is below minimum");
        shares = super.deposit(assets, receiver);
        emit VaultDeposit(receiver, assets, shares);
    }

    /// @notice Withdraw assets from the vault by burning shares
    /// @param shares The amount of shares to burn
    /// @param receiver The address of the receiver of the assets
    /// @param owner The address of the owner of the shares
    /// @return assets The amount of assets returned
    function withdraw(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256 assets) {
        assets = super.withdraw(shares, receiver, owner);
        emit VaultWithdrawal(receiver, assets, shares);
    }

    /// @notice Set a new minimum investment amount
    /// @param _minInvestment The new minimum investment amount
    function setMinInvestment(uint256 _minInvestment) external onlyOwner {
        minInvestment = _minInvestment;
        emit MinimumInvestmentChanged(_minInvestment);
    }

    /// @notice Calculate the total assets in the vault
    /// @return The total assets held in the vault
    function totalAssets() public view override returns (uint256) {
        return vaultToken.balanceOf(address(this));
    }

    /// @notice Convert a given amount of assets to shares
    /// @param assets The amount of assets to convert
    /// @return shares The equivalent shares
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        return super.convertToShares(assets);
    }

    /// @notice Convert a given amount of shares to assets
    /// @param shares The amount of shares to convert
    /// @return assets The equivalent assets
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        return super.convertToAssets(shares);
    }

    /// @notice Max deposit amount that can be made for a given receiver
    /// @param receiver The address of the receiver
    /// @return The maximum amount of assets that can be deposited
    function maxDeposit(address receiver) public view override returns (uint256) {
        return vaultToken.balanceOf(receiver);
    }

    /// @notice Max withdraw amount that can be made for a given owner
    /// @param owner The address of the owner
    /// @return The maximum amount of shares that can be withdrawn
    function maxWithdraw(address owner) public view override returns (uint256) {
        return maxRedeem(owner);
    }

    /// @notice Override required for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view override(ERC4626) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
